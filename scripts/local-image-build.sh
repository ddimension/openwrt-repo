#!/bin/bash
# Lokaler Voll-Buildroot-Image-Build im openwrt-builder-Container.
# Extrahiert aus .github/workflows/build-device-images.yml (chateau-Job) +
# .github/ci/build-images.sh — fuer lokale Nutzung mit podman ODER docker,
# Host-Verzeichnissen statt Named Volumes und Resume nach Build-Fehlern.
#
# Default-Geraet: MikroTik Chateau 5G R17 ax (qualcommax/ipq60xx) mit komplettem
# wwand-Stack. Ueber --target/--subtarget/--device/--src-url auch fuer beliebige
# andere Geraete und Architekturen nutzbar.
#
#   scripts/local-image-build.sh <release> [optionen] [-- <extra make-args>]
#
# <release>:
#   master|snapshot   -> Fork-Branch chateau-ci (openwrt main + Chateau-PR
#                        #24335 + QCA8081-Fix #24566 + ath11k-Fix #24601)
#   stable            -> Fork-Branch chateau-stable-backport (= 25.12 + PR)
#   sonst             -> upstream openwrt.git, Branch/Tag = <release>
#                        (z.B. openwrt-24.10, v24.10.2 — Chateau existiert dort
#                        NICHT, nur sinnvoll mit --device fuer upstream-Geraete)
#
# Beispiele:
#   scripts/local-image-build.sh master
#   scripts/local-image-build.sh stable -c ~/.cache/owrt -p "htop tcpdump"
#   scripts/local-image-build.sh master --resume              # nach Fehler weiter
#   scripts/local-image-build.sh master --resume -- V=s -j1   # Fehlersuche
#   scripts/local-image-build.sh openwrt-24.10 \
#     --target ramips --subtarget mt7621 --device zyxel_nr7101
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: local-image-build.sh <release> [optionen] [-- <extra make-args>]

Optionen:
  -p, --packages "P1 P2"  zusaetzliche Pakete ins Image (CONFIG_PACKAGE_x=y),
                          mehrfach angebbar
  -c, --cache DIR         Cache-Ordner: DIR/ccache (aktiviert CONFIG_CCACHE)
                          und DIR/dl (Download-Cache, sonst im Work-Dir)
  -w, --work DIR          Arbeitsverzeichnis (Quellbaum, persistent = Resume-
                          Basis)                     [default: ./build]
  -o, --out DIR           Artefakt-Ausgabe           [default: WORK/<slug>/out]
  -j N                    make-Parallelitaet         [default: nproc]
      --target T          OpenWrt-Target             [default: qualcommax]
      --subtarget S       OpenWrt-Subtarget          [default: ipq60xx]
      --device D          Geraeteprofil, mehrfach angebbar
                          [default: mikrotik_chateau-5g-r17-ax]
      --src-url URL       Quell-Repo (ueberschreibt Release-Mapping)
      --src-branch B      Quell-Branch/Tag (ueberschreibt Release-Mapping)
      --feed URL          wwand-Feed [default: https://github.com/ddimension/openwrt-repo.git]
      --no-wwand          wwand-Stack nicht ins Image aufnehmen
      --config FILE       zusaetzliches .config-Snippet anhaengen
      --patch FILE        Patch, der nach dem Checkout applied wird
      --image IMG         Builder-Image
                          [default: image-registry.ddimension.net/myadmin/openwrt-builder:latest]
      --engine E          podman|docker              [default: auto, podman bevorzugt]
      --testing-kernel    CONFIG_TESTING_KERNEL=y (KERNEL_TESTING_PATCHVER)
      --resume            Quell-Sync/feeds/.config ueberspringen, direkt
                          weiterbauen (nach Build-Fehler)
      --fresh             Quellbaum vorher loeschen (kompletter Neubau)
  -h, --help              diese Hilfe

Resume-Verhalten:
  Der Quellbaum inkl. build_dir/staging_dir bleibt unter WORK/<slug>/src
  erhalten — ein erneuter Lauf baut inkrementell weiter. --resume ueberspringt
  zusaetzlich git-fetch/feeds/defconfig und springt direkt zu make (schnellster
  Weg nach einem Fehler). --fresh wirft den Baum komplett weg.
EOF
	exit "${1:-0}"
}

# ---- Defaults (= chateau-Job der CI) ----------------------------------------
TARGET=qualcommax
SUBTARGET=ipq60xx
DEVICES=""
DEFAULT_DEVICE=mikrotik_chateau-5g-r17-ax
WWAND_FEED='https://github.com/ddimension/openwrt-repo.git'
IMAGE='image-registry.ddimension.net/myadmin/openwrt-builder:latest'
CHATEAU_FORK='https://github.com/ddimension/openwrt.git'
UPSTREAM='https://github.com/openwrt/openwrt.git'

RELEASE="" SRC_URL="" SRC_BRANCH="" EXTRA_PKGS="" CACHE_DIR="" WORK_DIR=./build
OUT_DIR="" JOBS="" ENGINE="" WWAND=1 CONFIG_EXTRA="" PATCH_FILE="" MODE=full
FRESH=0 TESTING_KERNEL="" EXTRA_MAKE=()

while [ $# -gt 0 ]; do
	case "$1" in
	-p | --packages) EXTRA_PKGS="$EXTRA_PKGS $2"; shift 2 ;;
	-c | --cache) CACHE_DIR="$2"; shift 2 ;;
	-w | --work) WORK_DIR="$2"; shift 2 ;;
	-o | --out) OUT_DIR="$2"; shift 2 ;;
	-j) JOBS="$2"; shift 2 ;;
	--target) TARGET="$2"; shift 2 ;;
	--subtarget) SUBTARGET="$2"; shift 2 ;;
	--device) DEVICES="$DEVICES $2"; shift 2 ;;
	--src-url) SRC_URL="$2"; shift 2 ;;
	--src-branch) SRC_BRANCH="$2"; shift 2 ;;
	--feed) WWAND_FEED="$2"; shift 2 ;;
	--no-wwand) WWAND=0; shift ;;
	--config) CONFIG_EXTRA="$2"; shift 2 ;;
	--patch) PATCH_FILE="$2"; shift 2 ;;
	--image) IMAGE="$2"; shift 2 ;;
	--engine) ENGINE="$2"; shift 2 ;;
	--testing-kernel) TESTING_KERNEL=1; shift ;;
	--resume) MODE=resume; shift ;;
	--fresh) FRESH=1; shift ;;
	-h | --help) usage ;;
	--) shift; EXTRA_MAKE=("$@"); break ;;
	-*) echo "Unbekannte Option: $1" >&2; usage 1 ;;
	*)
		[ -n "$RELEASE" ] && { echo "Nur ein Release-Argument erlaubt: '$1'" >&2; usage 1; }
		RELEASE="$1"; shift ;;
	esac
done
[ -n "$RELEASE" ] || { echo "FEHLER: <release> fehlt." >&2; usage 1; }
DEVICES="${DEVICES:-$DEFAULT_DEVICE}"
DEVICES="${DEVICES# }"

# ---- Release -> Quelle (nur wenn nicht explizit ueberschrieben) --------------
if [ -z "$SRC_BRANCH" ]; then
	case "$RELEASE" in
	# Integrations-Branch: openwrt main + Device-Support (#24335) + QCA8081-
	# TX-Clock-Fix (#24566) + ath11k-Reboot-Fix (#24601) — wie in der CI.
	master | snapshot) SRC_URL="${SRC_URL:-$CHATEAU_FORK}"; SRC_BRANCH=chateau-ci ;;
	stable) SRC_URL="${SRC_URL:-$CHATEAU_FORK}"; SRC_BRANCH=chateau-stable-backport ;;
	*)
		SRC_URL="${SRC_URL:-$UPSTREAM}"; SRC_BRANCH="$RELEASE"
		if [ "$DEVICES" = "$DEFAULT_DEVICE" ]; then
			echo "WARNUNG: Release '$RELEASE' kommt aus $SRC_URL — das Chateau-Geraet" >&2
			echo "         existiert nur in den Fork-Branches (master/stable)." >&2
		fi
		;;
	esac
fi
SRC_URL="${SRC_URL:-$UPSTREAM}"

# ---- Container-Engine: podman bevorzugt, docker als Fallback -----------------
if [ -z "$ENGINE" ]; then
	if command -v podman >/dev/null 2>&1; then ENGINE=podman
	elif command -v docker >/dev/null 2>&1; then ENGINE=docker
	else
		echo "FEHLER: weder podman noch docker gefunden — eines von beiden wird benoetigt." >&2
		exit 1
	fi
fi
command -v "$ENGINE" >/dev/null 2>&1 || { echo "FEHLER: $ENGINE nicht gefunden." >&2; exit 1; }

# ---- Verzeichnisse -----------------------------------------------------------
slug="$(echo "${DEVICES%% *}-${RELEASE}" | tr -c 'A-Za-z0-9._-' '-')"
slug="${slug%-}"
BASE_DIR="$WORK_DIR/$slug"
SRC_DIR="$BASE_DIR/src"
OUT_DIR="${OUT_DIR:-$BASE_DIR/out}"
if [ "$FRESH" = 1 ]; then
	echo ">> --fresh: loesche $SRC_DIR"
	rm -rf "$SRC_DIR"
fi
mkdir -p "$SRC_DIR" "$OUT_DIR"
if [ -n "$CACHE_DIR" ]; then
	DL_DIR="$CACHE_DIR/dl"
	CCACHE_DIR="$CACHE_DIR/ccache"
	mkdir -p "$DL_DIR" "$CCACHE_DIR"
else
	DL_DIR="$BASE_DIR/dl"
	CCACHE_DIR=""
	mkdir -p "$DL_DIR"
fi

# ---- wwand-.config-Snippet: aus dem Repo, sonst eingebetteter Stand ----------
script_dir="$(cd "$(dirname "$0")" && pwd)"
CONFIG_WWAND="$script_dir/../.github/ci/config.wwand"
if [ ! -r "$CONFIG_WWAND" ]; then
	CONFIG_WWAND="$BASE_DIR/config.wwand"
	cat > "$CONFIG_WWAND" <<'EOF'
# Kompletter wwand-Stack ins Image (built-in). Eingebetteter Fallback-Stand
# von .github/ci/config.wwand.
CONFIG_PACKAGE_wwand=y
CONFIG_PACKAGE_wwand-qmi=y
# CONFIG_PACKAGE_uqmi is not set
# CONFIG_PACKAGE_qmi-advanced is not set
CONFIG_PACKAGE_wwand-lpac=y
CONFIG_PACKAGE_luci-app-wwand=y
CONFIG_PACKAGE_luci-proto-wwand=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_umbim=y
CONFIG_PACKAGE_mbim-utils=y
CONFIG_PACKAGE_kmod-usb-net-cdc-mbim=y
CONFIG_PACKAGE_kmod-usb-net-qmi-wwan=y
CONFIG_PACKAGE_kmod-rmnet=y
CONFIG_PACKAGE_kmod-usb-serial-option=y
CONFIG_PACKAGE_kmod-vrf=y
CONFIG_LIBQMI_WITH_MBIM_QMUX=y
EOF
fi

# ---- In-Container-Buildscript (Variante von .github/ci/build-images.sh) ------
INNER="$BASE_DIR/inner.sh"
cat > "$INNER" <<'INNER_EOF'
#!/bin/bash
# Laeuft IM Container. Mounts: /src /dl /out (+ /ccache, /config.* , /patch.diff)
set -euo pipefail
: "${SRC_URL:?}"; : "${SRC_BRANCH:?}"; : "${TARGET:?}"; : "${SUBTARGET:?}"
: "${DEVICES:?}"; : "${MODE:?}"

export HOME=/tmp/home
mkdir -p "$HOME"
git config --global --add safe.directory /src
git config --global user.email "local@build"
git config --global user.name "local build"

cd /src
if [ "$MODE" = resume ]; then
	[ -f .config ] || { echo "FEHLER: kein .config im Quellbaum — --resume setzt einen frueheren Lauf voraus."; exit 4; }
	[ -L dl ] || { rm -rf dl; ln -s /dl dl; }
	echo ">> resume: git/feeds/.config uebersprungen"
else
	echo "== source ${SRC_BRANCH} (${SRC_URL}) =="
	if [ ! -d .git ]; then
		git clone --depth 100 --branch "$SRC_BRANCH" --single-branch "$SRC_URL" .
	else
		git remote set-url origin "$SRC_URL"
		git fetch --depth 100 --force origin "$SRC_BRANCH"
		git checkout -qf -B "$SRC_BRANCH" FETCH_HEAD
		git reset --hard FETCH_HEAD
	fi
	git --no-pager log --oneline -1

	# Download-Cache: OpenWrt nutzt $(TOPDIR)/dl -> auf das Cache-Volume symlinken
	[ -L dl ] || { rm -rf dl; ln -s /dl dl; }

	if [ -r /patch.diff ]; then
		echo "== patch =="
		git apply --index --whitespace=nowarn /patch.diff \
			|| { echo "FEHLER: Patch applied nicht sauber auf ${SRC_BRANCH}"; exit 2; }
	fi

	# Feeds: wwand-Feed ergaenzen
	cp -f feeds.conf.default feeds.conf
	if [ -n "${WWAND_FEED:-}" ]; then
		grep -q "$WWAND_FEED" feeds.conf || echo "src-git wwand ${WWAND_FEED}" >> feeds.conf
	fi
	echo "== feeds =="
	./scripts/feeds update -a
	./scripts/feeds install -a

	# .config seeden: Target/Subtarget/Devices + wwand-Stack + Extras + ccache
	{
		echo "CONFIG_TARGET_${TARGET}=y"
		echo "CONFIG_TARGET_${TARGET}_${SUBTARGET}=y"
		for d in $DEVICES; do
			echo "CONFIG_TARGET_${TARGET}_${SUBTARGET}_DEVICE_${d}=y"
		done
		[ -r /config.wwand ] && cat /config.wwand
		[ -r /config.extra ] && cat /config.extra
		for p in ${EXTRA_PKGS:-}; do
			echo "CONFIG_PACKAGE_${p}=y"
		done
		if [ -n "${CCACHE:-}" ]; then
			echo 'CONFIG_CCACHE=y'
			echo 'CONFIG_CCACHE_DIR="/ccache"'
		fi
		[ -n "${TESTING_KERNEL:-}" ] && echo 'CONFIG_TESTING_KERNEL=y'
		true
	} > .config
	[ -n "${TESTING_KERNEL:-}" ] && echo ">> TESTING_KERNEL aktiv (CONFIG_TESTING_KERNEL=y)"
	make defconfig

	echo "== verify selection =="
	for d in $DEVICES; do
		grep -q "CONFIG_TARGET_${TARGET}_${SUBTARGET}_DEVICE_${d}=y" .config \
			|| { echo "FEHLER: Geraet ${d} nach defconfig nicht selektiert"; exit 3; }
	done
	if [ -r /config.wwand ]; then
		grep -q '^CONFIG_PACKAGE_wwand=y' .config \
			|| { echo "FEHLER: wwand nicht selektiert (Feed ok?)"; exit 3; }
	fi
	for p in ${EXTRA_PKGS:-}; do
		grep -q "^CONFIG_PACKAGE_${p}=y" .config \
			|| echo "WARNUNG: Paket ${p} nach defconfig nicht =y (Name falsch oder Abhaengigkeit fehlt?)"
	done
	echo "selection ok"
fi

echo "== build =="
JOBS="${MAKE_JOBS:-$(nproc)}"
echo "make -j${JOBS} BUILD_LOG=1 $*"
if ! make -j"${JOBS}" BUILD_LOG=1 "$@"; then
	echo ""
	echo "BUILD FEHLGESCHLAGEN. Logs: WORK/<slug>/src/logs/"
	echo "Weiterbauen:   ... --resume"
	echo "Fehler finden: ... --resume -- V=s -j1"
	exit 1
fi

# Artefakte einsammeln
dst="/out/${TARGET}-${SUBTARGET}"
mkdir -p "$dst"
cp -a "bin/targets/${TARGET}/${SUBTARGET}/." "$dst/" 2>/dev/null || true
echo "=== artefakte ==="
find "$dst" -maxdepth 1 -type f \( -name '*.bin' -o -name '*.elf' -o -name '*.manifest' -o -name '*.buildinfo' -o -name 'sha256sums' \) -printf '  %f\n' | sort
INNER_EOF
chmod +x "$INNER"

# ---- Container-Aufruf --------------------------------------------------------
# SELinux (Fedora & Co.): Mounts brauchen ein Relabel-Flag
Z=""
if command -v selinuxenabled >/dev/null 2>&1 && selinuxenabled 2>/dev/null; then Z=",z"; fi

# OpenWrt baut nicht als root. Rootless podman: Host-User per keep-id in den
# Container mappen. Docker (rootful Daemon): Host-uid/gid direkt nutzen. Laeuft
# das Script selbst als root, stattdessen uid 1000 ('builder' im Image) + chown.
run_args=(--rm -e HOME=/tmp/home)
uid="$(id -u)" gid="$(id -g)"
if [ "$uid" = 0 ]; then
	chown -R 1000:1000 "$SRC_DIR" "$OUT_DIR" "$DL_DIR" ${CCACHE_DIR:+"$CCACHE_DIR"}
	run_args+=(--user 1000:1000)
elif [ "$ENGINE" = podman ]; then
	run_args+=(--userns=keep-id --user "$uid:$gid")
else
	run_args+=(--user "$uid:$gid")
fi
# fd-Limit deckeln: quasi-unbegrenztes nofile laesst fakeroot/apk in
# fd-close-Schleifen Minuten an CPU verbrennen (siehe scripts/local-build.sh)
run_args+=(--ulimit nofile=1024:1048576)

mounts=(
	-v "$(realpath "$SRC_DIR"):/src$Z"
	-v "$(realpath "$OUT_DIR"):/out$Z"
	-v "$(realpath "$DL_DIR"):/dl$Z"
	-v "$(realpath "$INNER"):/inner.sh:ro$Z"
)
[ "$WWAND" = 1 ] && mounts+=(-v "$(realpath "$CONFIG_WWAND"):/config.wwand:ro$Z")
[ -n "$CCACHE_DIR" ] && mounts+=(-v "$(realpath "$CCACHE_DIR"):/ccache$Z")
[ -n "$CONFIG_EXTRA" ] && mounts+=(-v "$(realpath "$CONFIG_EXTRA"):/config.extra:ro$Z")
[ -n "$PATCH_FILE" ] && mounts+=(-v "$(realpath "$PATCH_FILE"):/patch.diff:ro$Z")

envs=(
	-e SRC_URL="$SRC_URL" -e SRC_BRANCH="$SRC_BRANCH"
	-e TARGET="$TARGET" -e SUBTARGET="$SUBTARGET" -e DEVICES="$DEVICES"
	-e WWAND_FEED="$WWAND_FEED" -e MODE="$MODE"
	-e EXTRA_PKGS="${EXTRA_PKGS# }"
	-e MAKE_JOBS="${JOBS:-$(nproc)}"
	-e CCACHE="${CCACHE_DIR:+1}"
	-e TESTING_KERNEL="${TESTING_KERNEL}"
)

echo ">> engine=$ENGINE image=$IMAGE"
echo ">> release=$RELEASE src=$SRC_URL@$SRC_BRANCH"
echo ">> target=$TARGET/$SUBTARGET devices=[$DEVICES] mode=$MODE"
echo ">> src=$SRC_DIR out=$OUT_DIR dl=$DL_DIR ccache=${CCACHE_DIR:-aus}"

"$ENGINE" run "${run_args[@]}" "${envs[@]}" "${mounts[@]}" \
	"$IMAGE" bash /inner.sh "${EXTRA_MAKE[@]}"

echo ""
echo ">> fertig — Images unter: $OUT_DIR/${TARGET}-${SUBTARGET}/"
