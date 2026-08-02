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

echo "::group::build"
# MAKE_JOBS = vom Runner-CT freigegebene Kerne (im Workflow aus der cgroup-Quota
# ermittelt). Fallback auf nproc, wenn nicht gesetzt -- ACHTUNG: nproc meldet im
# LXC/Container die volle Node-Kernzahl, nicht die --cores-Quota (Ueberparallel-Risiko).
JOBS="${MAKE_JOBS:-$(nproc)}"
echo "make -j${JOBS}"
make -j"${JOBS}" BUILD_LOG=1
echo "::endgroup::"

# Artefakte einsammeln
dst="/out/${TARGET}-${SUBTARGET}"
mkdir -p "$dst"
cp -a "bin/targets/${TARGET}/${SUBTARGET}/." "$dst/" 2>/dev/null || true
echo "=== artefakte ==="
find "$dst" -maxdepth 1 -type f \( -name '*.bin' -o -name '*.elf' -o -name '*.manifest' -o -name '*.buildinfo' -o -name 'sha256sums' \) -printf '  %f\n' | sort
