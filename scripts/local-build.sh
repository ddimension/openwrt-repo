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
#   PACKAGES  source packages to build                 [.github/ci/packages]
#   NPROC     make parallelism inside the container    [8]
#   LOGDIR    per-combo build logs                     [/tmp/openwrt-repo-local-build]
#   SDKDIR    put each combo's SDK work tree in <SDKDIR>/sdk-<release>-<arch>
#             (a bind mount, kept after a PASS) instead of a docker volume —
#             builds here go under /vol/release/<project>   [unset: volume]
#   DDIMENSION_FEED_CHANNEL  tree ddimension-feed points at: main|stable [stable]
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
cd "$(dirname "$0")/.." || exit 1
FEED=$PWD
RELEASES="${RELEASES:-snapshot openwrt-25.12}"
ARCHS="${ARCHS:-aarch64_cortex-a53 aarch64_cortex-a72 aarch64_generic arm_cortex-a15_neon-vfpv4 arm_cortex-a7_neon-vfpv4 mips_24kc mipsel_24kc x86_64}"
# the list CI builds (.github/ci/packages; '#' starts a comment)
PACKAGES="${PACKAGES:-$(sed 's/#.*//' .github/ci/packages | xargs)}"
[ -n "$PACKAGES" ] || { echo "no packages: .github/ci/packages is empty" >&2; exit 1; }
NPROC="${NPROC:-8}"
LOGDIR="${LOGDIR:-/tmp/openwrt-repo-local-build}"

fail=0
for rel in $RELEASES; do
	for arch in $ARCHS; do
		tag=$arch
		[ "$rel" != "snapshot" ] && tag="$arch-$rel"
		vol="sdk-$rel-$arch"
		if [ -n "${SDKDIR:-}" ]; then
			vol="$SDKDIR/sdk-$rel-$arch"
			mkdir -p "$vol" && chmod 777 "$vol"
			# a bind mount hides the image's /builder (a new named volume is
			# seeded from it, a directory is not): copy it in once
			if [ -z "$(ls -A "$vol")" ]; then
				docker run --rm -v "$vol:/seed" "openwrt/sdk:$tag" sh -c 'cd /builder && tar -cf - $(ls -A) | tar -C /seed -xf -' ||
					{ echo "COMBO FAIL: $rel/$arch (could not seed $vol)"; fail=1; continue; }
			fi
		fi
		mkdir -p "$LOGDIR/$rel-$arch" && chmod 777 "$LOGDIR/$rel-$arch"
		echo "COMBO START: $rel/$arch"
		if docker run --rm --ulimit nofile=1024:1048576 \
			-e NPROC="$NPROC" -e PACKAGES="$PACKAGES" -e DDIMENSION_FEED_CHANNEL \
			-v "$vol:/builder" \
			-v "$FEED:/feed:ro" \
			-v "$LOGDIR/$rel-$arch:/logs" \
			"openwrt/sdk:$tag" sh /feed/scripts/sdk-inner.sh 2>&1; then
			echo "COMBO PASS: $rel/$arch"
			[ -n "${SDKDIR:-}" ] || docker volume rm -f "$vol" >/dev/null 2>&1
		else
			fail=1
			echo "COMBO FAIL: $rel/$arch (logs: $LOGDIR/$rel-$arch, SDK $vol kept)"
		fi
	done
done
echo "MATRIX DONE"
exit $fail
