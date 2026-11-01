#!/bin/bash
# Pin a git-source package of this feed to a tag or commit of its upstream
# repository, under a version number that means something.
#
#   scripts/bump-source.sh [--force] [--dry-run] [--channel main|stable] <package> <ref>
#   <ref>: tag (v1.6.5), branch, commit
#
# TWO LINES, TWO NUMBER SPACES. A source repo with a `stable` branch (the wwand
# stack) keeps releases and development apart, and so does its version:
#
#   feed stable  <- source stable, release tags vX.Y.Z:
#     v1.6.10              -> 1.6.10       a release: what stable ships
#     v1.6.10-3-g…         -> 1.6.10_p3    between releases (release-stable.sh refuses it)
#   feed main    <- source main, development markers vX.Y.Z-dev:
#     v1.7.0-dev-14-g…     -> 1.7.0_pre14
#
# apk orders 1.6.10 < 1.6.10_p3 < 1.7.0_pre1 < 1.7.0_pre14 < 1.7.0 < 1.7.0_p2
# (`apk version -t`, apk-tools of the openwrt snapshot host tree, 2026-10-04), so
# main always sorts above every stable patch release, and a merge of stable into
# main cannot change main's number: main only ever looks at -dev markers. The
# channel is the checked-out feed branch; --channel overrides it. The pinned
# commit must be on the source branch of the same name — a main commit cannot
# slip onto stable by a typo'd sha.
#
# A source repo WITHOUT a `stable` branch (apman, nsca-ng, … — one line only)
# keeps the single derivation on both channels:
#   v1.6.5 -> 1.6.5,  v1.6.5-7-gc27f72e -> 1.6.5_p7
#
# No build date gets into a version. (The date~commit form OpenWrt derives when
# PKG_VERSION is unset, 2026.09.11~c27f72e6, sorts above every real version
# number — moving away from it is a one-time downgrade.) PKG_RELEASE goes back
# to 1 with the new version; PKG_SOURCE_DATE is dropped. A packaging-only change
# of the same source is a PKG_RELEASE bump by hand, not a job for this script.
#
# Refused (--force overrides the last):
#   - the same version for a different commit: the source tarball is named
#     after the version, and the download caches would keep serving the old
#     file under that name. Tag a release instead.
#   - a commit that is not on the source branch of the channel (two-line repos)
#   - a version lower than the current one: devices would not upgrade to it.
#
# scripts/update-hashes.sh then computes the matching PKG_MIRROR_HASH. If that
# fails, the Makefile is restored — never a new version with the old hash.
# Commit the Makefile afterwards.
set -euo pipefail
cd "$(dirname "$0")/.."

die() { echo "bump-source: $*" >&2; exit 1; }

FORCE=0 DRY=0 channel=""
while [ $# -gt 0 ]; do
	case "$1" in
	--force) FORCE=1 ;;
	--dry-run) DRY=1 ;;
	--channel) channel="${2:-}"; shift ;;
	--*) die "unknown option $1" ;;
	*) break ;;
	esac
	shift
done
[ $# -eq 2 ] || die "usage: $0 [--force] [--dry-run] [--channel main|stable] <package> <ref>"
[ -n "$channel" ] || channel="$(git branch --show-current)"
case "$channel" in
main | stable) ;;
*) die "channel '$channel' is neither main nor stable — check out a feed branch or pass --channel" ;;
esac
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
# a bare clone carries the remote's branches as refs/heads/*
two_lines=0
if git -C "$tmp/src.git" rev-parse -q --verify refs/heads/stable >/dev/null; then
	two_lines=1
	git -C "$tmp/src.git" merge-base --is-ancestor "$sha" "refs/heads/$channel" ||
		die "${sha:0:12} is not on the $channel branch of $url — the feed's $channel pins its source's $channel"
fi

if [ "$two_lines" = 1 ] && [ "$channel" = main ]; then
	desc="$(git -C "$tmp/src.git" describe --tags --long --match 'v*-dev' "$sha" 2>/dev/null)" ||
		die "no vX.Y.Z-dev marker below $ref in $url — main counts from the marker of the minor it develops"
	# v1.7.0-dev-14-gc27f72e -> marker v1.7.0-dev, distance 14
	tag="${desc%-*-g*}"
	base="${tag#v}"
	base="${base%-dev}"
else
	desc="$(git -C "$tmp/src.git" describe --tags --long --match 'v[0-9]*' --exclude 'v*-*' "$sha" 2>/dev/null)" ||
		die "no vX.Y.Z tag below $ref in $url — tag a release there first"
	# v1.6.5-7-gc27f72e -> tag v1.6.5, distance 7
	tag="${desc%-*-g*}"
	base="${tag#v}"
fi
dist="${desc%-g*}"
dist="${dist##*-}"
case "$base" in
"" | *[!0-9.]* | .* | *. | *..*) die "tag $tag is not of the form vX.Y.Z" ;;
esac
if [ "$two_lines" = 1 ] && [ "$channel" = main ]; then
	ver="${base}_pre${dist}"
elif [ "$dist" = 0 ]; then
	ver="$base"
else
	ver="${base}_p${dist}"
fi

old_ver="$(sed -n -E 's/^PKG_VERSION[:?]?=//p' "$mk")"
old_rel="$(sed -n -E 's/^PKG_RELEASE[:?]?=//p' "$mk")"
old_sha="$(sed -n -E 's/^PKG_SOURCE_VERSION[:?]?=//p' "$mk")"
if [ "$old_ver" = "$ver" ]; then
	[ "$old_sha" != "$sha" ] || die "$pkg is already at $ver ($sha)"
	die "$ver is already the version of ${old_sha:0:12}; pinning ${sha:0:12} under the same version would reuse the tarball name — tag a release"
fi

# X.Y.Z[_preN|_pN] -> X.Y.Z.<class>.N, comparable with sort -V; the class
# carries apk's suffix order: _pre (0) < release (1) < _p (2)
verkey() {
	case "$1" in
	*_pre*) printf '%s.0.%s' "${1%_pre*}" "${1##*_pre}" ;;
	*_p*) printf '%s.2.%s' "${1%_p*}" "${1##*_p}" ;;
	*) printf '%s.1.0' "$1" ;;
	esac
}
if printf '%s' "$old_ver" | grep -Eq '^[0-9]+(\.[0-9]+)*(_pre[0-9]+|_p[0-9]+)?$'; then
	lower="$(printf '%s\n%s\n' "$(verkey "$old_ver")" "$(verkey "$ver")" | sort -V | head -n1)"
	if [ "$lower" = "$(verkey "$ver")" ] && [ "$FORCE" != 1 ]; then
		die "$old_ver -> $ver goes backwards, devices would not upgrade; --force if that is really meant"
	fi
fi

if [ "$DRY" = 1 ]; then
	echo "$pkg ($channel): ${old_ver:-(date~commit)}-r${old_rel:-?} @${old_sha:0:8} -> $ver-r1 @${sha:0:8}  ($desc) — dry run, nothing changed"
	exit 0
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
