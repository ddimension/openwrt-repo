#!/bin/bash
# Publish the package trees one feed build produced — without building again.
#
#   publish-feed.sh <run-id>                                    # a finished build run
#   publish-feed.sh --dir DIR --channel C --sha SHA [--run ID]  # trees already on disk
#
# The first form downloads the run's repo-* artifacts (gh CLI) and takes the
# channel and commit from the run itself; that is the repair path when a build
# went through and only its publish failed. The second form is what the build
# workflow's publish job calls with the artifacts it downloaded — one publish
# path for both.
#
# The channel is the branch the run built, main or stable; stable also
# rewrites the pre-channel mirror <release>/<arch>/. Every
# <release>/<arch>/packages.adb found is published; a leg that has none keeps
# its published state (publish-pages.sh guards that too).
#
# Only the newest commit of a branch publishes. If the branch has moved on
# since the run, its trees are older than what is or will be online, and this
# refuses (with a warning, exit 0) — a late publish must never roll a channel
# back.
#
# Why it exists: a feed build takes hours (14 legs of 50-75 minutes on three
# runners), the artifacts stay attached to the run for 30 days, and a failed
# publish should cost minutes, not another build.
#
# Env: GH_TOKEN (push credentials; defaults to `gh auth token`),
#      GITHUB_REPOSITORY [ddimension/openwrt-repo]. PAGES_* pass through to
#      publish-pages.sh (PAGES_REMOTE for a dry run against a bare repo).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
die() { echo "publish-feed: $*" >&2; exit 1; }

REPO="${GITHUB_REPOSITORY:-ddimension/openwrt-repo}"
DIR="" CHANNEL="" SHA="" RUN=""
case "${1:-}" in
--dir)
	while [ $# -gt 0 ]; do
		[ $# -ge 2 ] || die "$1 needs an argument"
		case "$1" in
		--dir) DIR="$2" ;;
		--channel) CHANNEL="$2" ;;
		--sha) SHA="$2" ;;
		--run) RUN="$2" ;;
		*) die "unknown argument $1" ;;
		esac
		shift 2
	done
	[ -n "$DIR" ] && [ -n "$CHANNEL" ] && [ -n "$SHA" ] || die "--dir needs --channel and --sha"
	[ -d "$DIR" ] || die "$DIR is not a directory"
	;;
[0-9]*)
	[ $# -eq 1 ] || die "usage: $0 <run-id>"
	RUN="$1"
	command -v gh >/dev/null || die "the gh CLI is needed to fetch run $RUN"
	info="$(gh api "repos/$REPO/actions/runs/$RUN" --jq '"\(.name) \(.head_branch) \(.head_sha)"')" ||
		die "run $RUN not found in $REPO"
	read -r name CHANNEL SHA <<<"$info"
	[ "$name" = build ] || die "run $RUN is a '$name' run, not a feed build"
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT
	gh run download "$RUN" -R "$REPO" -p 'repo-*' -D "$tmp/dl" ||
		die "no repo-* artifacts on run $RUN (they expire after 30 days)"
	DIR="$tmp/dl"
	;;
*) die "usage: $0 <run-id> | --dir DIR --channel C --sha SHA [--run ID]" ;;
esac
case "$CHANNEL" in
main | stable) ;;
*) die "'$CHANNEL' is not a channel (main or stable)" ;;
esac

tip="$(git ls-remote "https://github.com/$REPO.git" "refs/heads/$CHANNEL" | cut -f1)"
if [ -n "$tip" ] && [ "$tip" != "$SHA" ]; then
	echo "::warning::$CHANNEL is at ${tip:0:12} now; ${SHA:0:12}${RUN:+ (run $RUN)} is older and is not published"
	exit 0
fi

# …/<release>/<arch>/packages.adb, from the CI layout (DIR/<release>/<arch>)
# as well as from a downloaded run (DIR/repo-<release>-<arch>/<release>/<arch>)
pairs=() trees=0
while IFS= read -r adb; do
	d="${adb%/packages.adb}"
	arch="${d##*/}"
	rel="${d%/*}"
	rel="${rel##*/}"
	pairs+=("$d=$CHANNEL/$rel/$arch")
	trees=$((trees + 1))
	if [ "$CHANNEL" = stable ]; then
		pairs+=("$d=$rel/$arch")
	fi
done < <(find "$DIR" -name packages.adb | sort)
[ ${#pairs[@]} -gt 0 ] || die "no package trees (<release>/<arch>/packages.adb) under $DIR"

if [ -z "${GH_TOKEN:-}" ] && [ -z "${PAGES_REMOTE:-}" ] && command -v gh >/dev/null; then
	GH_TOKEN="$(gh auth token 2>/dev/null || true)"
	export GH_TOKEN
fi
export GITHUB_REPOSITORY="$REPO"
export PAGES_STAMP_SHA="$SHA" PAGES_STAMP_RUN="${RUN:-${GITHUB_RUN_ID:-local}}"
mirror=""
if [ "$CHANNEL" = stable ]; then mirror=" + the pre-channel mirror"; fi
echo "publish-feed: $CHANNEL @ ${SHA:0:12}${RUN:+, run $RUN}: $trees trees$mirror"
# not exec: the EXIT trap still has to remove the downloaded artifacts
"$here/publish-pages.sh" \
	-m "packages ($CHANNEL) @ $SHA${RUN:+ (run $RUN)}" \
	--channel "$CHANNEL" \
	--keys "$root/keys" \
	"${pairs[@]}"
