#!/bin/bash
# Release: tag a commit of the stable branch. The tag IS the release.
#
#   scripts/release-stable.sh [-y] [--allow-dev] [--no-ci-check] [<ref>]   # <ref> default: origin/stable
#
# stable is a branch of its own, not a pointer onto main: it is fed by
# cherry-picks, by scripts/stable-take.sh (packages, .github, or all of main),
# and by fixes made on stable and merged up into main. Pushing to stable only
# BUILDS (build.yml); devices and images see nothing until a release tag is
# pushed — that build publishes stable/<release>/<arch>/ and the pre-channel
# mirror <release>/<arch>/, and its success starts the device images
# (build-device-images.yml). So stable can be prepared over several pushes.
#
# Refused:
#   - <ref> not on origin/stable (push it there first, let it build);
#   - <ref> without a successful build run (--no-ci-check skips the check, for
#     a commit that only touched *.md and so built nothing, say);
#   - <ref> already released;
#   - a development version: X.Y.Z_pN or X.Y.Z_preN anywhere (see
#     scripts/bump-source.sh), and wwand, luci-app-wwand and luci-proto-wwand
#     must carry a real one — stable is what devices upgrade along, and that
#     only works with real version numbers. --allow-dev overrides.
# The tag is YYYY.MM.DD (.2, .3 … for a further release that day), annotated,
# its message the commits and package versions since the previous release tag.
# Nothing local is modified and nothing is checked out; -y skips the question.
#
# A fix that must not wait for main: commit it on stable (or cherry-pick it
# there), push, let it build, release; merge stable into main afterwards if the
# fix was made on stable. Nothing here requires stable to be part of main.
set -euo pipefail
cd "$(dirname "$0")/.."

die() { echo "release-stable: $*" >&2; exit 1; }

RELEASE_VERSIONED="wwand luci-app-wwand luci-proto-wwand"
REMOTE="${RELEASE_REMOTE:-origin}"
REPO="${RELEASE_REPO:-ddimension/openwrt-repo}"
YES=0
ALLOW_DEV=0
CI_CHECK=1
REF=""
while [ $# -gt 0 ]; do
	case "$1" in
	-y) YES=1 ;;
	--allow-dev) ALLOW_DEV=1 ;;
	--no-ci-check) CI_CHECK=0 ;;
	-h | --help) sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "$0"; exit 0 ;;
	-*) die "unknown option $1" ;;
	*) [ -z "$REF" ] || die "one ref only, got '$REF' and '$1'"; REF="$1" ;;
	esac
	shift
done
REF="${REF:-$REMOTE/stable}"

# Explicit refspec: a single-branch clone would otherwise never fetch stable.
git ls-remote --exit-code --heads "$REMOTE" stable >/dev/null ||
	die "$REMOTE has no stable branch"
git fetch -q "$REMOTE" "+refs/heads/stable:refs/remotes/$REMOTE/stable" ||
	die "fetching stable from $REMOTE failed"
git fetch -q --tags "$REMOTE" ||
	die "fetching tags from $REMOTE failed — a local tag that differs from the remote one?"

new="$(git rev-parse -q --verify "$REF^{commit}")" || die "unknown ref '$REF'"
git merge-base --is-ancestor "$new" "refs/remotes/$REMOTE/stable" ||
	die "$REF is not on $REMOTE/stable — push it to stable first, let it build there, then release"

# the previous release: the newest date tag below <ref>
prev="$(git describe --tags --abbrev=0 --match '20[0-9][0-9].[0-9][0-9].[0-9][0-9]*' "$new" 2>/dev/null || true)"
if [ -n "$prev" ]; then
	[ "$(git rev-parse "$prev^{commit}")" != "$new" ] ||
		{ echo "$(git log --oneline -1 "$new") is already released as $prev"; exit 0; }
	base="$prev"
	commits="$(git log --oneline --no-decorate "$prev..$new")"
else
	echo "no earlier release tag below $REF: everything counts as new"
	base="$(git hash-object -t tree /dev/null)" # empty tree: every package is new
	commits="(initial release)"
fi

if [ "$CI_CHECK" = 1 ]; then
	ok="$(gh run list -R "$REPO" -w build --commit "$new" --json conclusion \
		--jq '[.[] | select(.conclusion == "success")] | length' 2>/dev/null || echo 0)"
	[ "${ok:-0}" -gt 0 ] ||
		die "no successful build run for ${new:0:12} — wait for the stable build, or start one (gh workflow run build.yml -R $REPO --ref stable); --no-ci-check for a commit that built nothing"
fi

dev=""
while IFS= read -r f; do
	v="$(git show "$new:$f" | sed -n -E 's/^PKG_VERSION[:?]?=//p' | head -n1)"
	case "$v" in *_p[0-9]* | *_pre[0-9]*) dev+="  ${f%/Makefile}: $v"$'\n' ;; esac
done < <(git ls-tree --name-only "$new" -- ':(glob)*/Makefile' 2>/dev/null || git ls-tree -r --name-only "$new" | grep -E '^[^/]+/Makefile$')
for p in $RELEASE_VERSIONED; do
	v="$(git show "$new:$p/Makefile" 2>/dev/null | sed -n -E 's/^PKG_VERSION[:?]?=//p' | head -n1)"
	case "$v" in
	"" | *~*) dev+="  $p: ${v:-no PKG_VERSION (date~commit)}"$'\n' ;;
	esac
done
if [ -n "$dev" ]; then
	echo "development versions in $REF:" >&2
	printf '%s' "$dev" >&2
	[ "$ALLOW_DEV" = 1 ] ||
		die "pin tagged releases first (scripts/bump-source.sh <pkg> vX.Y.Z), or pass --allow-dev"
fi

# "<version>-r<release> @<source commit>" of one package Makefile, from stdin
pkgver() {
	awk -F'[:?]?=' '
		/^PKG_VERSION[:?]?=/        { v = $2 }
		/^PKG_RELEASE[:?]?=/        { r = $2 }
		/^PKG_SOURCE_VERSION[:?]?=/ { s = substr($2, 1, 8) }
		END {
			out = v
			if (r != "") out = out (out != "" ? "-" : "") "r" r
			if (s != "") out = out " @" s
			print out
		}'
}
changes=""
while IFS= read -r f; do
	pkg="${f%/Makefile}"
	o="$(git show "$base:$f" 2>/dev/null | pkgver || true)"
	n="$(git show "$new:$f" 2>/dev/null | pkgver || true)"
	[ "$o" = "$n" ] && continue
	changes+="$(printf '  %-20s %s -> %s' "$pkg" "${o:-(new)}" "${n:-(removed)}")"$'\n'
done < <(git diff --name-only "$base" "$new" -- ':(glob)*/Makefile')

# the day's tag, counting up past every tag that exists here or on the remote
taken="$( { git tag -l; git ls-remote --tags "$REMOTE" | sed -e 's#.*refs/tags/##' -e 's#\^{}$##'; } | sort -u)"
day="$(date -u +%Y.%m.%d)"
tag="$day"
n=2
while printf '%s\n' "$taken" | grep -qxF "$tag"; do
	tag="$day.$n"
	n=$((n + 1))
done

msg="Release $tag

Commits:
$(printf '%s\n' "$commits" | sed 's/^/  /')

Packages:
${changes:-  (no package version changes)}"

echo "release ${new:0:12} of stable as $tag${prev:+ (previous: $prev)}"
echo
echo "$msg"
echo
if [ "$YES" != 1 ]; then
	read -r -p "push tag $tag to $REMOTE (this publishes stable)? [y/N] " answer
	case "$answer" in y | Y | yes) ;; *) die "aborted" ;; esac
fi

git tag -a "$tag" "$new" -m "$msg"
if ! git push "$REMOTE" "refs/tags/$tag"; then
	git tag -d "$tag" >/dev/null
	die "push failed; the local tag $tag was removed again"
fi
echo "released $tag — the stable publish build is starting:"
echo "  gh run list -R $REPO -w build -L 3"
