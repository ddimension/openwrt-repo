#!/bin/bash
# Pin a git-source package of this feed to a tag or commit of its upstream
# repository, under a version number that means something.
#
#   scripts/bump-source.sh <package> <ref>     # <ref>: tag (v1.6.5), branch, commit
#
# The version comes from `git describe --tags --match 'v[0-9]*'` of that commit:
#
#   v1.6.5              -> PKG_VERSION 1.6.5      a release: what stable ships
#   v1.6.5-7-gc27f72e   -> PKG_VERSION 1.6.5_p7   7 commits after it: main
#
# apk orders them 1.6.5 < 1.6.5_p7 < 1.6.6, so both channels upgrade cleanly,
# and no build date gets into the version. (The date~commit form OpenWrt
# derives when PKG_VERSION is unset, 2026.09.11~c27f72e6, sorts above every
# real version number — moving away from it is a one-time downgrade.)
# PKG_RELEASE goes back to 1 whenever PKG_VERSION changes and otherwise counts
# packaging changes of the same version. PKG_SOURCE_DATE is dropped: with
# PKG_VERSION set, nothing uses it.
#
# scripts/update-hashes.sh then computes the matching PKG_MIRROR_HASH — the
# source tarball is named after the version, so the hash changes with it.
# Commit the Makefile afterwards. scripts/release-stable.sh refuses to release
# a development (_p) version of the packages it checks.
set -euo pipefail
cd "$(dirname "$0")/.."

die() { echo "bump-source: $*" >&2; exit 1; }

[ $# -eq 2 ] || die "usage: $0 <package> <ref>"
pkg="$1" ref="$2" mk="$1/Makefile"
[ -f "$mk" ] || die "no $mk"
grep -q '^PKG_SOURCE_PROTO:=git' "$mk" || die "$pkg is not a git-source package"
url="$(sed -n 's/^PKG_SOURCE_URL:=//p' "$mk")"
[ -n "$url" ] || die "$mk has no PKG_SOURCE_URL"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git clone -q --bare --filter=blob:none "$url" "$tmp/src.git"
sha="$(git -C "$tmp/src.git" rev-parse -q --verify "$ref^{commit}")" ||
	die "$ref not found in $url"
desc="$(git -C "$tmp/src.git" describe --tags --long --match 'v[0-9]*' "$sha" 2>/dev/null)" ||
	die "no v* tag below $ref in $url — tag a release there first"

# v1.6.5-7-gc27f72e -> tag v1.6.5, distance 7
tag="${desc%-*-g*}"
dist="${desc%-g*}"
dist="${dist##*-}"
base="${tag#v}"
case "$base" in
"" | *[!0-9.]* | .* | *. | *..*) die "tag $tag is not of the form vX.Y.Z" ;;
esac
if [ "$dist" = 0 ]; then ver="$base"; else ver="${base}_p${dist}"; fi

old_ver="$(sed -n 's/^PKG_VERSION:=//p' "$mk")"
old_rel="$(sed -n 's/^PKG_RELEASE:=//p' "$mk")"
old_sha="$(sed -n 's/^PKG_SOURCE_VERSION:=//p' "$mk")"
if [ "$old_sha" = "$sha" ] && [ "$old_ver" = "$ver" ]; then
	die "$pkg is already at $ver ($sha)"
fi
if [ "$old_ver" = "$ver" ]; then rel=$((old_rel + 1)); else rel=1; fi

sed -i \
	-e "s|^PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=$sha|" \
	-e "s|^PKG_RELEASE:=.*|PKG_RELEASE:=$rel|" \
	-e '/^PKG_SOURCE_DATE:=/d' \
	"$mk"
if grep -q '^PKG_VERSION:=' "$mk"; then
	sed -i "s|^PKG_VERSION:=.*|PKG_VERSION:=$ver|" "$mk"
else
	sed -i "/^PKG_NAME:=/a PKG_VERSION:=$ver" "$mk"
fi
echo "$pkg: ${old_ver:-(date~commit)}-r$old_rel @${old_sha:0:8} -> $ver-r$rel @${sha:0:8}  ($desc)"

scripts/update-hashes.sh "$pkg"
