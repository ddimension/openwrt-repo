#!/bin/bash
# Prune one published package tree to the last N versions of each package and
# rebuild its signed index — the container wrapper around apk-retention.py.
#
#   apk-retention.sh --dir DIR --keep N --arch ARCH [--key FILE]
#
# Why a container: apk v3 (mkndx, adbdump) exists neither on the runners nor on
# this host; only inside an OpenWrt SDK, which the publish job does not have.
# The image is Alpine plus python3 (~/projects/containers/apk-tools), in our own
# registry because docker.io's TLS timeouts have killed CI matrices before.
# Its apk 3.0.8 writes indexes that the SDK's 3.0.5 and the devices read.
#
# Env:
#   APK_TOOLS_IMAGE   image to run [image-registry.ddimension.net/myadmin/apk-tools:latest]
#   PUB_TIME, PUB_COMMIT, PUB_RUN   what a newly published version is stamped
#                     with in versions.json (publish-pages.sh passes its own)
#
# Fails loudly on purpose: a tree whose index could not be rebuilt must not be
# published, or it would advertise versions whose files are gone.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
die() { echo "apk-retention: $*" >&2; exit 1; }

DIR="" KEEP="" ARCH="" KEY=""
while [ $# -gt 0 ]; do
	[ $# -ge 2 ] || die "$1 needs an argument"
	case "$1" in
	--dir) DIR="$2" ;;
	--keep) KEEP="$2" ;;
	--arch) ARCH="$2" ;;
	--key) KEY="$2" ;;
	*) die "unknown argument $1" ;;
	esac
	shift 2
done
[ -n "$DIR" ] && [ -n "$KEEP" ] && [ -n "$ARCH" ] || die "--dir, --keep and --arch are required"
[ -d "$DIR" ] || die "$DIR is not a directory"
case "$KEEP" in
'' | *[!0-9]*) die "--keep must be a number, not '$KEEP'" ;;
esac
[ "$KEEP" -ge 1 ] || die "--keep must be at least 1"

IMAGE="${APK_TOOLS_IMAGE:-image-registry.ddimension.net/myadmin/apk-tools:latest}"
command -v docker >/dev/null || die "docker is needed to run $IMAGE"

args=(
	run --rm
	--user "$(id -u):$(id -g)"
	-v "$(cd "$DIR" && pwd):/w"
	-v "$here/apk-retention.py:/ci/apk-retention.py:ro"
	-v "$here/make-index-json.py:/ci/make-index-json.py:ro"
	-e PUB_TIME -e PUB_COMMIT -e PUB_RUN
)
inner=(python3 /ci/apk-retention.py --dir /w --keep "$KEEP" --arch "$ARCH")
if [ -n "$KEY" ]; then
	[ -f "$KEY" ] || die "signing key $KEY not found"
	args+=(-v "$(cd "$(dirname "$KEY")" && pwd)/$(basename "$KEY"):/key.pem:ro")
	inner+=(--key /key.pem)
else
	echo "::warning::apk-retention: no signing key, $DIR gets an UNSIGNED index"
fi
docker "${args[@]}" "$IMAGE" "${inner[@]}"
