#!/bin/bash
# In-Container OpenWrt-Image-Build (openwrt-builder, User uid 1000).
# Mounts:
#   /ci     = ci-images-Checkout (dieses Skript, chateau-pr.patch, config.wwand)
#   /src    = persistenter Quellbaum je Leg  (Named Volume owrt-src-<slug>)
#   /dl     = geteilter Download-Cache        (Named Volume owrt-dl)
#   /ccache = geteilter Compile-Cache         (Named Volume owrt-ccache)
#   /out    = Artefakt-Ausgabe (Workspace/out)
# Env: SRC_URL SRC_BRANCH PATCH TARGET SUBTARGET DEVICES WWAND_FEED
set -euo pipefail

: "${SRC_URL:?}"; : "${SRC_BRANCH:?}"; : "${TARGET:?}"; : "${SUBTARGET:?}"
: "${DEVICES:?}"; : "${WWAND_FEED:?}"; PATCH="${PATCH:-}"

export HOME=/home/builder
git config --global --add safe.directory /src
git config --global user.email "ci@ddimension.net"
git config --global user.name "ddimension ci"

cd /src
echo "::group::source ${SRC_BRANCH} (${SRC_URL})"
if [ ! -d .git ]; then
	git clone --depth 100 --branch "$SRC_BRANCH" --single-branch "$SRC_URL" .
else
	git remote set-url origin "$SRC_URL"
	git fetch --depth 100 --force origin "$SRC_BRANCH"
	git checkout -qf -B "$SRC_BRANCH" FETCH_HEAD
	git reset --hard FETCH_HEAD
fi
git --no-pager log --oneline -1
echo "::endgroup::"

if [ -n "$PATCH" ]; then
	echo "::group::backport ${PATCH}"
	git apply --index --whitespace=nowarn "/ci/${PATCH}" \
		|| { echo "FEHLER: Backport-Patch ${PATCH} applied nicht sauber auf ${SRC_BRANCH}"; exit 2; }
	echo "::endgroup::"
fi

# Download-Cache (OpenWrt nutzt $(TOPDIR)/dl)
rm -rf dl && ln -s /dl dl

# Feeds: wwand-Feed ergaenzen
cp -f feeds.conf.default feeds.conf
grep -q "$WWAND_FEED" feeds.conf || echo "src-git wwand ${WWAND_FEED}" >> feeds.conf
echo "::group::feeds"
./scripts/feeds update -a
./scripts/feeds install -a
echo "::endgroup::"

# .config seeden: Target/Subtarget/Devices + kompletter wwand-Stack + ccache
{
	echo "CONFIG_TARGET_${TARGET}=y"
	echo "CONFIG_TARGET_${TARGET}_${SUBTARGET}=y"
	for d in $DEVICES; do
		echo "CONFIG_TARGET_${TARGET}_${SUBTARGET}_DEVICE_${d}=y"
	done
	cat /ci/.github/ci/config.wwand
	echo 'CONFIG_CCACHE=y'
	echo 'CONFIG_CCACHE_DIR="/ccache"'
	# optional: Testing-Kernel (KERNEL_TESTING_PATCHVER) statt Default bauen
	[ -n "${TESTING_KERNEL:-}" ] && echo 'CONFIG_TESTING_KERNEL=y'
} > .config
[ -n "${TESTING_KERNEL:-}" ] && echo ">> TESTING_KERNEL aktiv (CONFIG_TESTING_KERNEL=y)"
make defconfig

echo "::group::verify device selection"
for d in $DEVICES; do
	grep -q "CONFIG_TARGET_${TARGET}_${SUBTARGET}_DEVICE_${d}=y" .config \
		|| { echo "FEHLER: Geraet ${d} nach defconfig nicht selektiert"; exit 3; }
done
grep -q '^CONFIG_PACKAGE_wwand=y' .config || { echo "FEHLER: wwand nicht selektiert (Feed ok?)"; exit 3; }
echo "device + wwand selection ok"
echo "::endgroup::"

# Stall-Wachhund. Am 2026-08-22 blieb der chateau-stable-Leg (Lauf 32545665275)
# 90 s nach Baubeginn ohne jede Ausgabe stehen -- letzte Zeile
# "make[4] scripts/config/conf" -- und lief 15 h ins Job-Timeout. Das kostet
# nicht nur den Lauf: build-device-images haelt eine Concurrency-Gruppe, der
# Haenger blockiert also jeden folgenden Image-Lauf mit. Dieselbe Signatur
# (keine Ausgabe, keine CPU-Last) hatte der qca-ssdk-Deadlock weiter unten.
# Statt stumm zu haengen: Diagnose ziehen und abbrechen.
STALL_LIMIT="${STALL_LIMIT:-2700}"   # 45 min ohne neue Ausgabe = haengt
STALL_POLL="${STALL_POLL:-15}"       # so oft nachsehen (kurz, damit fertige Stufen nicht warten)

stall_diagnose() {
	echo "=== Prozessbaum ==="
	ps -eo pid,ppid,stat,etime,pcpu,args --forest 2>/dev/null | tail -80
	echo "=== Load ==="
	cat /proc/loadavg 2>/dev/null
	echo "=== juengste Paket-Logs ==="
	find logs -name '*.txt' -mmin -180 2>/dev/null | head -5 | while read -r f; do
		echo "--- $f"
		tail -n 20 "$f"
	done
}

# run_watched <tag> <kommando...>: fuehrt das Kommando aus, streamt seine
# Ausgabe und bricht ab, wenn STALL_LIMIT lang nichts mehr dazukommt.
run_watched() {
	local tag="$1"; shift
	local log="/tmp/stage-${tag}.log" rcfile="/tmp/stage-${tag}.rc" mk tl age rc

	rm -f "$rcfile"; : > "$log"
	( "$@" >>"$log" 2>&1; echo "$?" > "$rcfile" ) &
	mk=$!
	tail -f -n +1 "$log" & tl=$!

	while kill -0 "$mk" 2>/dev/null; do
		sleep "$STALL_POLL"
		age=$(( $(date +%s) - $(stat -c %Y "$log" 2>/dev/null || echo 0) ))
		[ "$age" -gt "$STALL_LIMIT" ] || continue

		# stdout allein reicht als Signal nicht: mit BUILD_LOG=1 landet die
		# Paketausgabe in logs/, und ein einzelnes langes Paket (gcc im
		# toolchain/install) schreibt minutenlang keine Zeile nach stdout.
		# Zweite Meinung vom Dateisystem einholen -- ein laufender Build fasst
		# staendig Dateien an. Der find laeuft nur, wenn stdout schon still ist.
		if find logs build_dir/hostpkg build_dir/toolchain-* build_dir/target-* \
			-type f -newermt "-${STALL_LIMIT} seconds" -print -quit 2>/dev/null | grep -q .; then
			echo ">> ${tag}: stdout seit ${age}s still, aber der Baum arbeitet noch -- weiter"
			continue
		fi

		if true; then
			echo "::error::Stufe '${tag}' haengt: seit ${age}s keine Ausgabe (Limit ${STALL_LIMIT}s)"
			stall_diagnose
			pkill -9 -P "$mk" 2>/dev/null || true
			kill -9 "$mk" 2>/dev/null || true
			echo 124 > "$rcfile"
			break
		fi
	done

	wait "$mk" 2>/dev/null || true
	sleep 1; kill "$tl" 2>/dev/null || true
	rc="$(cat "$rcfile" 2>/dev/null || echo 1)"
	[ "$rc" = 0 ] || echo "Stufe '${tag}' endete mit rc=${rc}"
	return "$rc"
}

echo "::group::build"
# MAKE_JOBS = vom Runner-CT freigegebene Kerne (im Workflow aus der cgroup-Quota
# ermittelt). Fallback auf nproc, wenn nicht gesetzt -- ACHTUNG: nproc meldet im
# LXC/Container die volle Node-Kernzahl, nicht die --cores-Quota (Ueberparallel-Risiko).
JOBS="${MAKE_JOBS:-$(nproc)}"
echo "make -j${JOBS}"

# qca-ssdk (Qualcomm SSDK, out-of-tree Kernel-Modul) haengt beim parallelen Build
# reproduzierbar fest -- 'make[3] -C package/kernel/qca-ssdk compile' bleibt ohne
# CPU-Last stehen (Jobserver-Deadlock), v.a. auf dem 25.12/6.12 chateau-stable-Leg.
# Darum: die schweren Voraussetzungen parallel bauen, qca-ssdk dann ALLEIN
# single-threaded, danach der volle parallele Build (qca-ssdk ist dann fertig und
# wird uebersprungen). Auf Legs, die nicht haengen wuerden, ist das nur strukturiert.
if [ -d package/kernel/qca-ssdk ]; then
	echo ">> qca-ssdk: prereqs parallel, dann qca-ssdk -j1 (Deadlock-Vermeidung)"
	run_watched prereqs make -j"${JOBS}" tools/install toolchain/install target/linux/compile BUILD_LOG=1
	run_watched qca-ssdk make -j1 package/kernel/qca-ssdk/compile BUILD_LOG=1
fi

run_watched world make -j"${JOBS}" BUILD_LOG=1
echo "::endgroup::"

# Artefakte einsammeln
dst="/out/${TARGET}-${SUBTARGET}"
mkdir -p "$dst"
cp -a "bin/targets/${TARGET}/${SUBTARGET}/." "$dst/" 2>/dev/null || true
echo "=== artefakte ==="
find "$dst" -maxdepth 1 -type f \( -name '*.bin' -o -name '*.elf' -o -name '*.manifest' -o -name '*.buildinfo' -o -name 'sha256sums' \) -printf '  %f\n' | sort
