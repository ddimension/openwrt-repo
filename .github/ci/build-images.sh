#!/bin/bash
# In-Container OpenWrt-Image-Build (openwrt-builder, User uid 1000).
# Mounts:
#   /ci     = Repo-Checkout (dieses Skript, config.wwand)
#   /src    = persistenter Quellbaum je Leg  (Named Volume owrt-src-<slug>-<base>)
#   /dl     = geteilter Download-Cache        (Named Volume owrt-dl)
#   /ccache = geteilter Compile-Cache         (Named Volume owrt-ccache)
#   /out    = Artefakt-Ausgabe (Workspace/out)
# Env: SRC_URL SRC_BRANCH PATCH SLUG TARGET SUBTARGET DEVICES WWAND_FEED
#   SLUG waehlt zusaetzlich .github/ci/config.<slug>, falls vorhanden
#   WWAND_FEED ist die src-git-Quelle dieses Feeds: <url>;<branch> (Kanal-Spitze)
#   oder <url>^<sha> (genau ein Commit). scripts/feeds merkt sich die Quelle und
#   klont feeds/wwand neu, sobald sie sich aendert.
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

# Feeds: wwand-Feed ergaenzen. Eine vorhandene wwand-Zeile fliegt vorher raus —
# ein Quell-Branch darf seine eigene mitbringen (der lte3301-Branch tut es, mit
# der UNGEPINNTEN URL), und `grep -qF` auf unsere gepinnte Form wuerde sie nicht
# erkennen: feeds.conf haette dann zweimal den Feed-Namen 'wwand', und welcher
# Klon gewinnt, entscheidet scripts/feeds — der Pin waere nicht mehr garantiert.
cp -f feeds.conf.default feeds.conf
sed -i '/^src-[a-z-]\{1,\}[[:space:]]\{1,\}wwand[[:space:]]/d' feeds.conf
echo "src-git wwand ${WWAND_FEED}" >> feeds.conf
# Ein gepinnter Feed (<url>^<sha>) wird von scripts/feeds nach dem Klonen nie
# mehr aktualisiert, und die Quelle merkt es sich VOR dem Klonen. Brach ein
# frueherer Lauf zwischen clone und checkout ab (Netz, Abbruch), steht
# feeds/wwand auf dem falschen Baum -- und derselbe Pin baute ihn stumm weiter.
# Also pruefen und im Zweifel wegwerfen; feeds update klont dann neu.
case "$WWAND_FEED" in
*^*)
	want="${WWAND_FEED##*^}"
	have="$(git -C feeds/wwand rev-parse HEAD 2>/dev/null || true)"
	if [ "$have" != "$want" ]; then
		echo "feeds/wwand steht auf '${have:-nichts}', nicht auf dem Pin $want -- neu klonen"
		rm -rf feeds/wwand feeds/wwand.tmp feeds/wwand.index
	fi
	;;
esac
echo "::group::feeds"
./scripts/feeds update -a
./scripts/feeds install -a
echo "::endgroup::"

# Ein Geraet oder mehrere? Mehrere gehen NICHT ueber die Profil-Symbole:
# target-metadata.pl legt alle TARGET_<conf>_DEVICE_* in EINE kconfig-choice
# ("Target Profile"), ein zweites =y ueberschreibt dort nur das erste
# (confdata.c: "changes choice state") -- defconfig behielte das letzte Geraet
# und die verify-Schleife unten scheiterte am ersten. Fuer mehrere Geraete ist
# TARGET_MULTI_PROFILE mit den Menue-Symbolen TARGET_DEVICE_<conf>_DEVICE_<name>
# vorgesehen; die defaulten nur unter TARGET_ALL_PROFILES auf y
# (metadata.pm: `default => "y if TARGET_ALL_PROFILES"`), es kommt also kein
# weiteres Geraet des Subtargets dazu. Ein-Geraet-Legs behalten die alte Form,
# damit ihr warmer Baum nicht wegen eines Config-Wechsels neu baut.
ndev=0
for d in $DEVICES; do ndev=$((ndev + 1)); done

# .config seeden: Target/Subtarget/Devices + kompletter wwand-Stack + ccache
{
	echo "CONFIG_TARGET_${TARGET}=y"
	echo "CONFIG_TARGET_${TARGET}_${SUBTARGET}=y"
	if [ "$ndev" -gt 1 ]; then
		echo "CONFIG_TARGET_MULTI_PROFILE=y"
		for d in $DEVICES; do
			echo "CONFIG_TARGET_DEVICE_${TARGET}_${SUBTARGET}_DEVICE_${d}=y"
		done
	else
		for d in $DEVICES; do
			echo "CONFIG_TARGET_${TARGET}_${SUBTARGET}_DEVICE_${d}=y"
		done
	fi
	cat /ci/.github/ci/config.wwand
	# Optionaler Zusatz je Leg: .github/ci/config.<slug> (z.B. config.chateau
	# mit kmod-usb-serial-ftdi). Fehlt die Datei, bleibt es beim gemeinsamen
	# Stack -- die anderen Legs aendert ein Geraete-Zusatz also nicht.
	if [ -n "${SLUG:-}" ] && [ -f "/ci/.github/ci/config.$SLUG" ]; then
		cat "/ci/.github/ci/config.$SLUG"
	fi
	echo 'CONFIG_CCACHE=y'
	echo 'CONFIG_CCACHE_DIR="/ccache"'
	# optional: Testing-Kernel (KERNEL_TESTING_PATCHVER) statt Default bauen
	[ -n "${TESTING_KERNEL:-}" ] && echo 'CONFIG_TESTING_KERNEL=y'
} > .config
[ -n "${TESTING_KERNEL:-}" ] && echo ">> TESTING_KERNEL aktiv (CONFIG_TESTING_KERNEL=y)"
make defconfig

echo "::group::verify device selection"
for d in $DEVICES; do
	if [ "$ndev" -gt 1 ]; then
		sym="CONFIG_TARGET_DEVICE_${TARGET}_${SUBTARGET}_DEVICE_${d}=y"
	else
		sym="CONFIG_TARGET_${TARGET}_${SUBTARGET}_DEVICE_${d}=y"
	fi
	grep -q "^${sym}$" .config \
		|| { echo "FEHLER: Geraet ${d} nach defconfig nicht selektiert (${sym})"; exit 3; }
done
grep -q '^CONFIG_PACKAGE_wwand=y' .config || { echo "FEHLER: wwand nicht selektiert (Feed ok?)"; exit 3; }
# CONFIG_TESTING_KERNEL haengt an HAS_TESTING_KERNEL, das nur gesetzt ist, wenn
# das Target ein KERNEL_TESTING_PATCHVER hat (include/target.mk). Fehlt das,
# wirft defconfig das Symbol still weg und der Leg baut den Default-Kernel --
# der Lauf soll das nicht trotzdem als Testing-Kernel ausgeben.
if [ -n "${TESTING_KERNEL:-}" ] && ! grep -q '^CONFIG_TESTING_KERNEL=y' .config; then
	echo "::warning::${TARGET}/${SUBTARGET} hat keinen Testing-Kernel (kein KERNEL_TESTING_PATCHVER) -- gebaut wird der Default-Kernel"
fi
# Der Pro-Leg-Zusatz muss defconfig ueberleben: ein Symbol, das das Target nicht
# kennt, wirft defconfig still wieder raus -- dann fehlt es im Image, ohne dass
# der Bau scheitert. Also hier pruefen statt spaeter im Manifest suchen.
if [ -n "${SLUG:-}" ] && [ -f "/ci/.github/ci/config.$SLUG" ]; then
	while read -r sym; do
		grep -q "^${sym}$" .config \
			|| { echo "FEHLER: ${sym} aus config.$SLUG nach defconfig nicht gesetzt"; exit 3; }
	done <<-LIST
		$(grep '^CONFIG_PACKAGE_[A-Za-z0-9_-]*=y$' "/ci/.github/ci/config.$SLUG")
	LIST
	echo "config.$SLUG selection ok"
fi
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
	# Achtung: der Build-Container hat kein procps -- ein blankes `ps` bricht mit
	# 127 ab und riss unter `set -e` die ganze Diagnose mit (Lauf 32640281922).
	# Deshalb alles aus /proc, und der Aufrufer haengt ein `|| true` an.
	echo "=== Load ==="
	cat /proc/loadavg 2>/dev/null

	echo "=== Prozesse (pid state wchan cmd) ==="
	# state zeigt, ob noch jemand rechnet (R) oder alle warten (S/D);
	# wchan nennt die Kernelfunktion, in der ein blockierter Task haengt.
	for d in /proc/[0-9]*; do
		[ -r "$d/stat" ] || continue
		cmd=$(tr '\0' ' ' < "$d/cmdline" 2>/dev/null | cut -c1-90)
		[ -n "$cmd" ] || continue
		# Status steht nach der letzten Klammer: comm darf Leerzeichen und
		# Klammern enthalten, feste Feldnummern verrutschen daran.
		st=$(sed 's/.*) //' "$d/stat" 2>/dev/null | cut -d' ' -f1)
		echo "  ${d#/proc/} ${st:-?} $(cat "$d/wchan" 2>/dev/null || echo '?') $cmd"
	done 2>/dev/null | head -60

	echo "=== offene Netzverbindungen (haengender Download?) ==="
	grep -c . /proc/net/tcp 2>/dev/null | sed 's/^/  tcp-Eintraege: /'

	echo "=== juengste Paket-Logs ==="
	find logs -name '*.txt' -mmin -180 2>/dev/null | head -5 | while read -r f; do
		echo "--- $f"
		tail -n 20 "$f" 2>/dev/null
	done
}

# Die ganze Prozessgruppe einer Stufe abraeumen. Die Gruppen-Id ist die PID der
# Subshell (setsid in run_watched); ein negatives Signalziel trifft alle darin.
# Danach die Reste, die sich abgekoppelt haben: fakeroots faked haengt an
# keinem make-Kind mehr, sobald sein Elternteil weg ist.
stage_kill() {
	local pid="$1"
	kill -9 -- "-$pid" 2>/dev/null || true
	kill -9 "$pid" 2>/dev/null || true
	# procps ist im Container nicht garantiert -> ueber /proc gehen.
	for d in /proc/[0-9]*; do
		[ -r "$d/cmdline" ] || continue
		case "$(tr '\0' ' ' <"$d/cmdline" 2>/dev/null)" in
		*fakeroot*apk\ mkpkg* | *bin/faked*) kill -9 "${d#/proc/}" 2>/dev/null || true ;;
		esac
	done
	# kurz warten, bis der Kernel die Gruppe wirklich abgeraeumt hat
	kill -0 "$pid" 2>/dev/null && sleep 3
	true
}

# run_watched <tag> <kommando...>: fuehrt das Kommando aus, streamt seine
# Ausgabe und bricht ab, wenn STALL_LIMIT lang nichts mehr dazukommt.
run_watched() {
	local tag="$1"; shift
	local log="/tmp/stage-${tag}.log" rcfile="/tmp/stage-${tag}.rc" mk tl age rc

	rm -f "$rcfile"; : > "$log"
	# setsid: die Stufe bekommt eine eigene Session, ihre PID ist damit auch
	# die Prozessgruppen-Id. Nur so laesst sich beim Abbruch der GANZE Baum
	# killen (make -> bash -> perl -> make -> fakeroot -> faked). `pkill -P`
	# erwischt nur direkte Kinder, und der Rest lief danach munter weiter: im
	# nr7101-stable-Leg (Lauf 37214945447) haengte der zweite, serielle
	# Versuch an genau denselben fakeroot-Prozessen des ersten.
	( setsid "$@" >>"$log" 2>&1; echo "$?" > "$rcfile" ) &
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
		# build_dir/host und staging_dir gehoeren dazu: die tools-Phase eines
		# kalten Baums arbeitet dort und sonst nirgends in dieser Liste.
		if find logs build_dir/host build_dir/hostpkg build_dir/toolchain-* \
			build_dir/target-* staging_dir \
			-type f -newermt "-${STALL_LIMIT} seconds" -print -quit 2>/dev/null | grep -q .; then
			echo ">> ${tag}: stdout seit ${age}s still, aber der Baum arbeitet noch -- weiter"
			continue
		fi

		if true; then
			echo "::error::Stufe '${tag}' haengt: seit ${age}s keine Ausgabe (Limit ${STALL_LIMIT}s)"
			stall_diagnose || true
			stage_kill "$mk"
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
# Nur auf qualcommax: openwrt-25.12 hat das Paket im Baum JEDES Targets (main
# nicht mehr), und auf ramips ist es nicht selektiert -- dort scheiterte
# `package/kernel/qca-ssdk/compile` sofort und riss den nr7101-stable-Leg mit,
# waehrend derselbe Leg auf master gruen war.
if [ -d package/kernel/qca-ssdk ] && [ "$TARGET" = qualcommax ]; then
	echo ">> qca-ssdk: prereqs parallel, dann qca-ssdk -j1 (Deadlock-Vermeidung)"
	run_watched prereqs make -j"${JOBS}" tools/install toolchain/install target/linux/compile BUILD_LOG=1
	run_watched qca-ssdk make -j1 package/kernel/qca-ssdk/compile BUILD_LOG=1
fi

# Ein Hänger ist nicht dasselbe wie ein Fehler: rc=124 heisst, der Wachhund hat
# abgebrochen, weil 45 min nichts passiert ist. Gesehen am 2026-10-04 im
# nr7101-stable-Leg (Lauf 37194316303): zwei `apk mkpkg` unter fakeroot standen
# ohne CPU-Last in pipe_read, ihre faked-Prozesse in do_select -- derselbe
# Abdruck wie beim fd-Limit-Problem, nur hing `--ulimit nofile=1024:1048576`
# diesmal nachweislich am Container. Es trifft sporadisch zwei PARALLELE
# mkpkg; serialisiert kam derselbe Baum durch. Also: einmal aufräumen und mit
# -j1 weitermachen. Der Baum ist an der Stelle praktisch fertig gebaut, es geht
# nur noch ums Packen -- -j1 kostet dort Minuten, nicht Stunden.
rc=0
run_watched world make -j"${JOBS}" BUILD_LOG=1 || rc=$?
if [ "$rc" = 124 ]; then
	echo "::warning file=${SLUG:-image}::Stufe 'world' hing (rc=124), einmal serieller Versuch mit -j1"
	# stage_kill hat die Gruppe schon abgeraeumt; kurz Luft lassen, damit der
	# Kernel die Sockets der faked-Prozesse wirklich schliesst.
	sleep 5
	rc=0
	run_watched world-j1 make -j1 BUILD_LOG=1 || rc=$?
fi
[ "$rc" = 0 ] || exit "$rc"
echo "::endgroup::"

# Artefakte einsammeln
dst="/out/${TARGET}-${SUBTARGET}"
mkdir -p "$dst"
cp -a "bin/targets/${TARGET}/${SUBTARGET}/." "$dst/" 2>/dev/null || true
echo "=== artefakte ==="
find "$dst" -maxdepth 1 -type f \( -name '*.bin' -o -name '*.elf' -o -name '*.manifest' -o -name '*.buildinfo' -o -name 'sha256sums' \) -printf '  %f\n' | sort
