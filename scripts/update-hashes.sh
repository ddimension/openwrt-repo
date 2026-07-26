#!/bin/bash
# Recompute PKG_MIRROR_HASH for the git-source packages of this feed and
# write the values into the Makefiles.
#
#   scripts/update-hashes.sh              # all git-source packages
#   scripts/update-hashes.sh wwand        # just one (after a version bump)
#
# Run this after every PKG_SOURCE_VERSION bump, commit the Makefile change.
# CI runs gh-action-sdk in per-package mode, whose check hard-fails on a
# missing/stale/'skip' mirror hash.
#
# WHY THIS SCRIPT: the mirror hash is the sha256 of the tarball OpenWrt's
# own dl_tar_pack produces, and that stream depends on the SDK's tar/zstd
# versions. Host-side replication (git archive + host tar/zstd) has produced
# WRONG values before — the only authoritative source is the SDK's own
# download+check, which prints the expected value. So we run exactly that in
# the official SDK container. Hashes are branch-independent (verified
# identical on master and release SDKs).
#
# Env: SDK_TAG (default x86_64 = master SDK), LOGDIR for the raw output.
set -eu
cd "$(dirname "$0")/.."
FEED=$PWD
SDK_TAG="${SDK_TAG:-x86_64}"
LOGDIR="${LOGDIR:-/tmp/openwrt-repo-hash-update}"
mkdir -p "$LOGDIR" && chmod 777 "$LOGDIR"

# git-source packages (PKG_SOURCE_PROTO:=git) unless given as arguments
if [ $# -gt 0 ]; then
	PKGS="$*"
else
	PKGS=$(grep -l '^PKG_SOURCE_PROTO:=git' ./*/Makefile | xargs -n1 dirname | xargs -n1 basename | sort)
fi
echo "packages: $PKGS"

cat >"$LOGDIR/inner.sh" <<'EOF'
#!/bin/sh
set -u
cd /builder
if [ ! -x scripts/feeds ]; then
	./setup.sh >/logs/setup.log 2>&1 || { echo "SETUP FAILED"; tail -5 /logs/setup.log; exit 1; }
fi
grep -q "src-link wwand /feed" feeds.conf.default 2>/dev/null ||
	echo "src-link wwand /feed" >>feeds.conf.default
./scripts/feeds update -a >/logs/feeds.log 2>&1
./scripts/feeds install -a -p wwand >>/logs/feeds.log 2>&1
make defconfig >/logs/defconfig.log 2>&1
: >/logs/hashes.txt
for pkg in $PKGS; do
	rm -f dl/"$pkg"-* 2>/dev/null
	out=$( (make "package/feeds/wwand/$pkg/download" V=s 2>&1;
	        make "package/feeds/wwand/$pkg/check" V=s 2>&1) |
		grep -oE "(set to|got) [0-9a-f]{64}" | tail -1 | awk '{print $NF}')
	if [ -n "$out" ]; then
		echo "$pkg $out" >>/logs/hashes.txt
		echo "COMPUTED: $pkg $out"
	else
		echo "$pkg KEEP" >>/logs/hashes.txt
		echo "UNCHANGED: $pkg (current hash already correct)"
	fi
done
EOF

docker run --rm --ulimit nofile=1024:1048576 \
	-e PKGS="$PKGS" \
	-v openwrt-repo-hash-sdk:/builder \
	-v "$FEED:/feed:ro" \
	-v "$LOGDIR:/logs" \
	"openwrt/sdk:$SDK_TAG" sh /logs/inner.sh

# write results into the Makefiles
while read -r pkg hash; do
	[ "$hash" = "KEEP" ] && continue
	if grep -q '^PKG_MIRROR_HASH:=' "$pkg/Makefile"; then
		sed -i "s|^PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=$hash|" "$pkg/Makefile"
	else
		sed -i "/^PKG_SOURCE:=/a PKG_MIRROR_HASH:=$hash" "$pkg/Makefile"
	fi
	echo "UPDATED: $pkg/Makefile -> $hash"
done <"$LOGDIR/hashes.txt"

echo "done — review with: git diff */Makefile"
