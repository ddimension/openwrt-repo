#!/bin/bash
# ImageBuilder-Bau (apk) fuer upstream-Geraete (nr7101, lte3301-plus) — kein
# Toolchain-Build. Bindet den wwand-Feed aus gh-pages SIGNIERT ein (Public-Key in
# keys/, CONFIG_SIGNATURE_CHECK bleibt an). Laeuft im openwrt-builder-Container.
# Mounts: /ci (ci-images: dieses Skript + keys/), /work (Scratch), /out (Artefakte).
# Env: BASE(master|stable) DEVICES GHP_DIR ARCH FEED_ROOT
set -euo pipefail

: "${BASE:?}"; : "${DEVICES:?}"; : "${GHP_DIR:?}"
ARCH="${ARCH:-mipsel_24kc}"
FEED_ROOT="${FEED_ROOT:-https://ddimension.github.io/openwrt-repo}"
export HOME=/home/builder
cd /work

# 1) offiziellen ramips/mt7621 ImageBuilder holen (snapshot bzw. neuestes 25.12.x)
if [ "$BASE" = "master" ]; then
	IB_DIR="https://downloads.openwrt.org/snapshots/targets/ramips/mt7621"
else
	REL="$(wget -qO- https://downloads.openwrt.org/releases/ | grep -oE '25\.12\.[0-9]+/' | tr -d / | sort -V | uniq | tail -1)"
	[ -n "$REL" ] || { echo "FEHLER: keine 25.12.x Release gefunden"; exit 2; }
	echo "stable release: $REL"
	IB_DIR="https://downloads.openwrt.org/releases/${REL}/targets/ramips/mt7621"
fi
IBFILE="$(wget -qO- "$IB_DIR/" | grep -oE 'openwrt-imagebuilder-[^"]*ramips-mt7621\.Linux-x86_64\.tar\.(zst|xz)' | head -1)"
[ -n "$IBFILE" ] || { echo "FEHLER: ImageBuilder nicht gefunden unter $IB_DIR"; exit 2; }
echo "::group::download $IBFILE"
wget -qO ib.tar "$IB_DIR/$IBFILE"
rm -rf ib && mkdir ib && tar -C ib --strip-components=1 -xaf ib.tar
echo "::endgroup::"
cd ib

# 2) wwand-Feed SIGNIERT einbinden
cp -f /ci/keys/ddimension.pem keys/ddimension.pem
FEED="${FEED_ROOT}/${GHP_DIR}/${ARCH}"
echo "${FEED}/packages.adb" >> repositories
echo "signierter Feed: ${FEED}/packages.adb (Key: keys/ddimension.pem)"

PKGS="wwand wwand-lpac luci-app-wwand luci-proto-wwand \
umbim mbim-utils kmod-usb-net-cdc-mbim kmod-usb-net-qmi-wwan kmod-rmnet \
kmod-usb-serial-option kmod-vrf luci"

# 3) je Geraet ein Image (Signaturpruefung aktiv)
for d in $DEVICES; do
	echo "::group::make image PROFILE=$d ($BASE)"
	make image PROFILE="$d" PACKAGES="$PKGS"
	echo "::endgroup::"
done

# 4) Artefakte
dst="/out/ramips-mt7621-${BASE}"
mkdir -p "$dst"
cp -a bin/targets/ramips/mt7621/. "$dst/" 2>/dev/null || true
echo "=== artefakte ==="
find "$dst" -maxdepth 1 -type f \( -name '*.bin' -o -name '*.manifest' -o -name 'sha256sums' \) -printf '  %f\n' | sort
