#!/bin/bash
# Pin a git-source package of this feed to a tag or commit of its upstream
# repository, under a version number that means something.
#
#   scripts/bump-source.sh [--force] <package> <ref>   # <ref>: tag (v1.6.5), branch, commit
#
# The version comes from `git describe --tags --match 'v[0-9]*'` of that commit
# (release candidates like v1.6.6-rc1 are ignored):
#
#   v1.6.5              -> PKG_VERSION 1.6.5      a release: what stable ships
#   v1.6.5-7-gc27f72e   -> PKG_VERSION 1.6.5_p7   7 commits after it: main
#
# apk orders them 1.6.5 < 1.6.5_p7 < 1.6.6, so both channels upgrade cleanly,
# and no build date gets into the version. (The date~commit form OpenWrt
# derives when PKG_VERSION is unset, 2026.09.11~c27f72e6, sorts above every
# real version number — moving away from it is a one-time downgrade.)
# PKG_RELEASE goes back to 1 with the new version; PKG_SOURCE_DATE is dropped,
# with PKG_VERSION set nothing uses it. A packaging-only change of the same
# source is a PKG_RELEASE bump by hand, not a job for this script.
#
# Refused (--force overrides the second):
#   - the same version for a different commit: the source tarball is named
#     after the version, and the download caches would keep serving the old
#     file under that name. Tag a release instead.
#   - a version lower than the current one: devices would not upgrade to it.
#
# scripts/update-hashes.sh then computes the matching PKG_MIRROR_HASH. If that
# fails, the Makefile is restored — never a new version with the old hash.
# Commit the Makefile afterwards. scripts/release-stable.sh refuses to release
# a development (_p) version.
set -euo pipefail
cd "$(dirname "$0")/.."

die() { echo "bump-source: $*" >&2; exit 1; }

FORCE=0
if [ "${1:-}" = --force ]; then FORCE=1; shift; fi
[ $# -eq 2 ] || die "usage: $0 [--force] <package> <ref>"
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
desc="$(git -C "$tmp/src.git" describe --tags --long --match 'v[0-9]*' --exclude 'v*-*' "$sha" 2>/dev/null)" ||
	die "no vX.Y.Z tag below $ref in $url — tag a release there first"

# v1.6.5-7-gc27f72e -> tag v1.6.5, distance 7
tag="${desc%-*-g*}"
dist="${desc%-g*}"
dist="${dist##*-}"
base="${tag#v}"
case "$base" in
"" | *[!0-9.]* | .* | *. | *..*) die "tag $tag is not of the form vX.Y.Z" ;;
esac
if [ "$dist" = 0 ]; then ver="$base"; else ver="${base}_p${dist}"; fi

old_ver="$(sed -n -E 's/^PKG_VERSION[:?]?=//p' "$mk")"
old_rel="$(sed -n -E 's/^PKG_RELEASE[:?]?=//p' "$mk")"
old_sha="$(sed -n -E 's/^PKG_SOURCE_VERSION[:?]?=//p' "$mk")"
if [ "$old_ver" = "$ver" ]; then
	[ "$old_sha" != "$sha" ] || die "$pkg is already at $ver ($sha)"
	die "$ver is already the version of ${old_sha:0:12}; pinning ${sha:0:12} under the same version would reuse the tarball name — tag a release"
fi

# X.Y.Z[_pN] -> X.Y.Z.N (a release is N=0), comparable with sort -V
verkey() {
	case "$1" in
	*_p*) printf '%s.%s' "${1%_p*}" "${1##*_p}" ;;
	*) printf '%s.0' "$1" ;;
	esac
}
if printf '%s' "$old_ver" | grep -Eq '^[0-9]+(\.[0-9]+)*(_p[0-9]+)?$'; then
	lower="$(printf '%s\n%s\n' "$(verkey "$old_ver")" "$(verkey "$ver")" | sort -V | head -n1)"
	if [ "$lower" = "$(verkey "$ver")" ] && [ "$FORCE" != 1 ]; then
		die "$old_ver -> $ver goes backwards, devices would not upgrade; --force if that is really meant"
	fi
fi

cp "$mk" "$tmp/Makefile.orig" # restored if the hash cannot be computed
sed -i -E \
	-e "s|^PKG_SOURCE_VERSION[:?]?=.*|PKG_SOURCE_VERSION:=$sha|" \
	-e "s|^PKG_RELEASE[:?]?=.*|PKG_RELEASE:=1|" \
	-e '/^PKG_SOURCE_DATE[:?]?=/d' \
	"$mk"
if grep -Eq '^PKG_VERSION[:?]?=' "$mk"; then
	sed -i -E "s|^PKG_VERSION[:?]?=.*|PKG_VERSION:=$ver|" "$mk"
else
	sed -i "/^PKG_NAME:=/a PKG_VERSION:=$ver" "$mk"
fi
echo "$pkg: ${old_ver:-(date~commit)}-r${old_rel:-?} @${old_sha:0:8} -> $ver-r1 @${sha:0:8}  ($desc)"

# A new version without its hash would be a Makefile that cannot build; put
# the old one back rather than leave half a bump behind.
if ! scripts/update-hashes.sh "$pkg"; then
	cp "$tmp/Makefile.orig" "$mk"
	die "no mirror hash for $pkg — $mk restored, nothing changed"
fi
