#!/bin/bash
# Test-build this feed locally in the official openwrt/sdk Docker containers
# BEFORE burning CI minutes — same SDK, same checks as the GitHub workflow.
#
#   scripts/local-build.sh                          # full default matrix
#   ARCHS=x86_64 scripts/local-build.sh             # one arch
#   RELEASES=snapshot ARCHS=aarch64_cortex-a53 \
#     PACKAGES=wwand scripts/local-build.sh         # one package, one combo
#
# Env knobs (defaults match the CI workflow):
#   RELEASES  release branches ('snapshot' = master)   [snapshot openwrt-25.12]
#   ARCHS     package architectures                    [7-arch CI matrix]
#   PACKAGES  source packages to build                 [CI package set]
#   NPROC     make parallelism inside the container    [8]
#   LOGDIR    per-combo build logs                     [/tmp/openwrt-repo-local-build]
#
# Behaviour:
# - one persistent docker volume per <release>/<arch> keeps the SDK setup and
#   built deps across iterations; it is deleted after a PASS, kept on FAIL so
#   a fix only rebuilds the failed package.
# - --ulimit nofile is REQUIRED: docker's default (~unlimited) makes
#   fakeroot/apk-mkpkg burn minutes of CPU per package (fd-close loop).
# - any kmod-* dependency makes the SDK package the whole kernel-module tree
#   once per fresh volume (~30-40 min) — expected, not a hang.
set -u
cd "$(dirname "$0")/.."
FEED=$PWD
RELEASES="${RELEASES:-snapshot openwrt-25.12}"
ARCHS="${ARCHS:-aarch64_cortex-a53 aarch64_cortex-a72 arm_cortex-a15_neon-vfpv4 arm_cortex-a7_neon-vfpv4 mips_24kc mipsel_24kc x86_64}"
PACKAGES="${PACKAGES:-luacurl lua-mosquitto usb-relay-hid apman wwand wwand-lpac luci-app-wwand luci-proto-wwand}"
NPROC="${NPROC:-8}"
LOGDIR="${LOGDIR:-/tmp/openwrt-repo-local-build}"

fail=0
for rel in $RELEASES; do
	for arch in $ARCHS; do
		tag=$arch
		[ "$rel" != "snapshot" ] && tag="$arch-$rel"
		vol="sdk-$rel-$arch"
		mkdir -p "$LOGDIR/$rel-$arch" && chmod 777 "$LOGDIR/$rel-$arch"
		echo "COMBO START: $rel/$arch"
		if docker run --rm --ulimit nofile=1024:1048576 \
			-e NPROC="$NPROC" -e PACKAGES="$PACKAGES" \
			-v "$vol:/builder" \
			-v "$FEED:/feed:ro" \
			-v "$LOGDIR/$rel-$arch:/logs" \
			"openwrt/sdk:$tag" sh /feed/scripts/sdk-inner.sh 2>&1; then
			echo "COMBO PASS: $rel/$arch"
			docker volume rm -f "$vol" >/dev/null 2>&1
		else
			fail=1
			echo "COMBO FAIL: $rel/$arch (logs: $LOGDIR/$rel-$arch, volume $vol kept)"
		fi
	done
done
echo "MATRIX DONE"
exit $fail
