#!/bin/bash
# Take things from main onto the stable branch — partly or wholly.
#
#   scripts/stable-take.sh [-y] <package>...   # those package directories, as on origin/main
#   scripts/stable-take.sh [-y] --ci           # .github/ (workflows and CI scripts)
#   scripts/stable-take.sh [-y] --all          # merge origin/main into stable
#
# stable is a branch of its own (scripts/release-stable.sh): it takes from main
# what is ready and leaves the rest. A package directory or .github/ is copied
# over in one commit on top of origin/stable, its message naming the main commit
# it came from; --all is a real merge. Nothing goes live by this — the push
# builds stable, a release tag publishes it.
#
# A stack package (wwand, luci-app-wwand, luci-proto-wwand) taken from main
# brings main's X.Y.Z_preN development version along, and release-stable.sh
# refuses to release that: those reach stable through their source's stable
# branch instead — check out stable and run scripts/bump-source.sh <pkg> vX.Y.Z.
# Ordinary `git cherry-pick -x <commit>` onto stable stays just as fine.
#
# Works in a temporary worktree: the current checkout is never touched. -y
# pushes without asking.
set -euo pipefail
cd "$(dirname "$0")/.."

die() { echo "stable-take: $*" >&2; exit 1; }

REMOTE="${RELEASE_REMOTE:-origin}"
YES=0 MODE=paths
paths=()
while [ $# -gt 0 ]; do
	case "$1" in
	-y) YES=1 ;;
	--ci) paths+=(.github) ;;
	--all) MODE=merge ;;
	-h | --help) sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "$0"; exit 0 ;;
	-*) die "unknown option $1" ;;
	*) paths+=("${1%/}") ;;
	esac
	shift
done
[ "$MODE" = merge ] || [ ${#paths[@]} -gt 0 ] || die "nothing to take: name packages, --ci or --all"

git fetch -q "$REMOTE" "+refs/heads/main:refs/remotes/$REMOTE/main" \
	"+refs/heads/stable:refs/remotes/$REMOTE/stable" || die "fetching main/stable from $REMOTE failed"
main="$(git rev-parse "refs/remotes/$REMOTE/main")"

wt="$(mktemp -d)"
trap 'git worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"' EXIT
git worktree add -q --detach "$wt" "refs/remotes/$REMOTE/stable"

if [ "$MODE" = merge ]; then
	git -C "$wt" merge --no-ff -m "Merge main into stable (${main:0:12})" "$main" ||
		die "the merge has conflicts — resolve them by hand (git switch -c take $REMOTE/stable && git merge $REMOTE/main)"
else
	for p in "${paths[@]}"; do
		git cat-file -e "$main:$p" 2>/dev/null || die "$p does not exist on $REMOTE/main"
		# exactly main's directory: files main removed go too
		git -C "$wt" rm -r -q --ignore-unmatch -- "$p"
		git -C "$wt" checkout "$main" -- "$p"
	done
	git -C "$wt" add -A -- "${paths[@]}"
	if git -C "$wt" diff --cached --quiet; then
		echo "stable already has ${paths[*]} as on main (${main:0:12})"
		exit 0
	fi
	git -C "$wt" commit -q -m "stable: take ${paths[*]} from main

From $REMOTE/main ${main:0:12} ($(git log -1 --format=%s "$main"))."
fi

git -C "$wt" log --oneline "refs/remotes/$REMOTE/stable..HEAD"
git -C "$wt" diff --stat "refs/remotes/$REMOTE/stable" HEAD | tail -n 5
if [ "$YES" != 1 ]; then
	read -r -p "push this to $REMOTE/stable (builds, publishes nothing)? [y/N] " answer
	case "$answer" in y | Y | yes) ;; *) die "aborted — nothing pushed" ;; esac
fi
git -C "$wt" push -q "$REMOTE" HEAD:refs/heads/stable
echo "pushed — the stable build is starting; release with scripts/release-stable.sh once it is green"
