#!/bin/bash
# Release: move the stable branch forward to a commit of main and tag it.
#
#   scripts/release-stable.sh [-y] [--allow-dev] [<ref>]   # <ref> default: origin/main
#
# stable only ever moves forward — the ruleset on GitHub refuses anything else,
# and so would every src-git checkout of this feed (`git pull --ff-only`):
#   - <ref> must be on origin/main (built and published there first) and must
#     contain the current stable. If it does not, stable carries a hotfix that
#     main lacks: merge origin/stable into main first.
#   - no package may carry a development version (X.Y.Z_pN, see
#     scripts/bump-source.sh), and wwand, luci-app-wwand and luci-proto-wwand
#     must have a real one: stable is what devices upgrade along, and that
#     only works with real version numbers. --allow-dev overrides.
#   - the push fast-forwards refs/heads/stable to <ref> and adds an annotated
#     tag YYYY.MM.DD (.2, .3 … for a further release that day) whose message
#     lists the commits and the package versions that change. Branch and tag
#     go in one atomic push.
# Nothing local is modified and nothing is checked out; -y skips the question.
#
# The push starts the stable feed build (build.yml): it publishes
# stable/<release>/<arch>/ and the pre-channel mirror <release>/<arch>/, and
# its success starts the device images (build-device-images.yml). A release
# that changes only *.md files starts no build (paths-ignore); start one with
# `gh workflow run build.yml -R ddimension/openwrt-repo --ref stable`.
#
# A hotfix that must not wait for main:
#   git switch -c hotfix origin/stable     # fix, commit
#   git push origin HEAD:stable            # builds and publishes stable
#   git tag -a YYYY.MM.DD -m "..." && git push origin YYYY.MM.DD   # .2 if taken
#   git switch main && git merge origin/stable && git push   # back into main
set -euo pipefail
cd "$(dirname "$0")/.."

die() { echo "release-stable: $*" >&2; exit 1; }

RELEASE_VERSIONED="wwand luci-app-wwand luci-proto-wwand"
REMOTE="${RELEASE_REMOTE:-origin}"
YES=0
ALLOW_DEV=0
REF=""
while [ $# -gt 0 ]; do
	case "$1" in
	-y) YES=1 ;;
	--allow-dev) ALLOW_DEV=1 ;;
	-h | --help) sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "$0"; exit 0 ;;
	-*) die "unknown option $1" ;;
	*) [ -z "$REF" ] || die "one ref only, got '$REF' and '$1'"; REF="$1" ;;
	esac
	shift
done
REF="${REF:-$REMOTE/main}"

# Explicit refspecs: a single-branch clone would otherwise never fetch stable
# and this script would take it for a first release.
stable_exists=0
if git ls-remote --exit-code --heads "$REMOTE" stable >/dev/null; then stable_exists=1; fi
specs=("+refs/heads/main:refs/remotes/$REMOTE/main")
[ "$stable_exists" = 1 ] && specs+=("+refs/heads/stable:refs/remotes/$REMOTE/stable")
git fetch -q "$REMOTE" "${specs[@]}" || die "fetching main/stable from $REMOTE failed"
git fetch -q --tags "$REMOTE" ||
	die "fetching tags from $REMOTE failed — a local tag that differs from the remote one?"

new="$(git rev-parse -q --verify "$REF^{commit}")" || die "unknown ref '$REF'"
git merge-base --is-ancestor "$new" "refs/remotes/$REMOTE/main" ||
	die "$REF is not on $REMOTE/main — push it to main first, let it build there, then release"

if [ "$stable_exists" = 1 ]; then
	old="$(git rev-parse "refs/remotes/$REMOTE/stable^{commit}")"
	[ "$old" != "$new" ] || { echo "stable is already at $(git log --oneline -1 "$new")"; exit 0; }
	if ! git merge-base --is-ancestor "$old" "$new"; then
		echo "stable has commits that $REF lacks (a hotfix?):" >&2
		git log --oneline "$new..$old" | sed 's/^/    /' >&2
		die "merge $REMOTE/stable into main first, then release again"
	fi
	base="$old"
	commits="$(git log --oneline --no-decorate "$old..$new")"
else
	old=""
	echo "stable does not exist yet: it will be created at $REF"
	base="$(git hash-object -t tree /dev/null)" # empty tree: every package is new
	commits="(initial release)"
fi

dev=""
while IFS= read -r f; do
	v="$(git show "$new:$f" | sed -n -E 's/^PKG_VERSION[:?]?=//p' | head -n1)"
	case "$v" in *_p[0-9]*) dev+="  ${f%/Makefile}: $v"$'\n' ;; esac
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

echo "stable: ${old:0:12}${old:+ -> }${new:0:12}   tag: $tag"
echo
echo "$msg"
echo
if [ "$YES" != 1 ]; then
	read -r -p "push stable and tag $tag to $REMOTE? [y/N] " answer
	case "$answer" in y | Y | yes) ;; *) die "aborted" ;; esac
fi

git tag -a "$tag" "$new" -m "$msg"
if ! git push --atomic "$REMOTE" "$new:refs/heads/stable" "refs/tags/$tag"; then
	git tag -d "$tag" >/dev/null
	die "push failed; the local tag $tag was removed again"
fi
echo "released $tag — the stable feed build is starting:"
echo "  gh run list -R ddimension/openwrt-repo -w build --branch stable -L 1"
