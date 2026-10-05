#!/bin/bash
# Publish the package trees one feed build produced — without building again.
#
#   publish-feed.sh <run-id> [--force]                          # a finished build run
#   publish-feed.sh --dir DIR --channel C --sha SHA [--run ID] [--tag T] [--force]
#
# The first form downloads the run's repo-* artifacts (gh CLI) and takes the
# channel and commit from the run itself; that is the repair path when a build
# went through and only its publish failed. The second form is what the build
# workflow's publish job calls with the artifacts it downloaded — one publish
# path for both.
#
# main publishes from a push to the main branch; stable ONLY from a release
# tag (YYYY.MM.DD[.N], scripts/release-stable.sh) — a push to the stable branch
# builds and publishes nothing. stable also rewrites the pre-channel mirror
# <release>/<arch>/. Every <release>/<arch>/packages.adb found is published; a
# leg that has none keeps its published state (publish-pages.sh guards that too).
#
# A late publish must never roll a channel back, so this refuses (with a
# warning, exit 0) when main has moved on since the run, or when the release
# tag no longer points at the run's commit or a newer release tag exists.
#
# --force lifts exactly that check, for the one case where it is a false
# alarm: the commits that landed since the build touched no package at all
# (CI, scripts, docs), so the run's trees are still what the tip would
# produce. Check that before using it — `git diff --name-only <run-sha>..<tip>`
# must show nothing but .github/, scripts/ and *.md. build.yml's publish_run
# dispatch takes this path.
#
# Why it exists: a feed build takes hours (14 legs of 50-75 minutes on three
# runners), the artifacts stay attached to the run for 30 days, and a failed
# publish should cost minutes, not another build.
#
# Versions: each published tree keeps the last KEEP_VERSIONS [10] versions of
# every package, so a device can go back (apk add <pkg>=<version>). The
# pre-channel mirror keeps one — it is the "current stable" path for devices
# from before the channels, nothing downgrades along it. publish-pages.sh does
# the merging and rebuilds the signed index for it.
#
# Env: KEEP_VERSIONS [10], RELEASE_ASSETS=0 to skip the GitHub release copy,
#      GH_TOKEN (push credentials; defaults to `gh auth token`),
#      GITHUB_REPOSITORY [ddimension/openwrt-repo]. PAGES_* pass through to
#      publish-pages.sh (PAGES_REMOTE for a dry run against a bare repo).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
die() { echo "publish-feed: $*" >&2; exit 1; }

REPO="${GITHUB_REPOSITORY:-ddimension/openwrt-repo}"
RELEASE_TAG_RE='^20[0-9]{2}\.[0-9]{2}\.[0-9]{2}(\.[0-9]+)?$'
DIR="" CHANNEL="" SHA="" RUN="" TAG="" FORCE=0
case "${1:-}" in
--dir)
	while [ $# -gt 0 ]; do
		# --force first: it takes no argument, so the arity check below would
		# reject it as the last word on the line.
		if [ "$1" = --force ]; then
			FORCE=1
			shift
			continue
		fi
		[ $# -ge 2 ] || die "$1 needs an argument"
		case "$1" in
		--dir) DIR="$2" ;;
		--channel) CHANNEL="$2" ;;
		--sha) SHA="$2" ;;
		--run) RUN="$2" ;;
		--tag) TAG="$2" ;;
		*) die "unknown argument $1" ;;
		esac
		shift 2
	done
	[ -n "$DIR" ] && [ -n "$CHANNEL" ] && [ -n "$SHA" ] || die "--dir needs --channel and --sha"
	[ -d "$DIR" ] || die "$DIR is not a directory"
	;;
[0-9]*)
	RUN="$1"
	shift
	while [ $# -gt 0 ]; do
		case "$1" in
		--force) FORCE=1 ;;
		*) die "usage: $0 <run-id> [--force]" ;;
		esac
		shift
	done
	command -v gh >/dev/null || die "the gh CLI is needed to fetch run $RUN"
	info="$(gh api "repos/$REPO/actions/runs/$RUN" --jq '"\(.name) \(.head_branch) \(.head_sha)"')" ||
		die "run $RUN not found in $REPO"
	read -r name CHANNEL SHA <<<"$info"
	[ "$name" = build ] || die "run $RUN is a '$name' run, not a feed build"
	# a tag run's head_branch is the tag: a release, published as stable
	if printf '%s' "$CHANNEL" | grep -Eq "$RELEASE_TAG_RE"; then
		TAG="$CHANNEL"
		CHANNEL=stable
	elif [ "$CHANNEL" = stable ]; then
		die "run $RUN built the stable branch, which publishes nothing — release a tag (scripts/release-stable.sh)"
	fi
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

remote="https://github.com/$REPO.git"
if [ "$CHANNEL" = stable ]; then
	[ -n "$TAG" ] || die "stable publishes only from a release tag (--tag); a stable branch build publishes nothing"
	printf '%s' "$TAG" | grep -Eq "$RELEASE_TAG_RE" || die "'$TAG' is not a release tag (YYYY.MM.DD[.N])"
	# the commit behind the tag (an annotated tag lists it as <tag>^{})
	tagsha="$(git ls-remote --tags "$remote" "refs/tags/$TAG" "refs/tags/$TAG^{}" |
		awk '{ s[$2] = $1 } END { print (s["refs/tags/'"$TAG"'^{}"] != "" ? s["refs/tags/'"$TAG"'^{}"] : s["refs/tags/'"$TAG"'"]) }')"
	if [ "$tagsha" != "$SHA" ] && [ "$FORCE" != 1 ]; then
		echo "::warning::release tag $TAG is at ${tagsha:0:12}, not ${SHA:0:12}${RUN:+ (run $RUN)} — not published"
		exit 0
	fi
	latest="$(git ls-remote --tags "$remote" | sed -n 's#.*refs/tags/##p' | grep -v '\^{}$' |
		grep -E "$RELEASE_TAG_RE" | sort -V | tail -n1)"
	if [ -n "$latest" ] && [ "$latest" != "$TAG" ] && [ "$FORCE" != 1 ]; then
		echo "::warning::$latest is a newer release than $TAG — not published"
		exit 0
	fi
else
	tip="$(git ls-remote "$remote" "refs/heads/$CHANNEL" | cut -f1)"
	if [ -n "$tip" ] && [ "$tip" != "$SHA" ]; then
		if [ "$FORCE" != 1 ]; then
			echo "::warning::$CHANNEL is at ${tip:0:12} now; ${SHA:0:12}${RUN:+ (run $RUN)} is older and is not published"
			exit 0
		fi
		echo "::warning::--force: $CHANNEL is at ${tip:0:12}, publishing the older ${SHA:0:12} anyway"
	fi
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
# Host tools the build produced next to the packages (CI collects them as
# tools/<arch>/): they are not part of any repository index, so they go to
# tools/<channel>/<arch>/ — one place per channel, linked from the start page.
if [ -d "$DIR/tools" ]; then
	while IFS= read -r td; do
		pairs+=("$td=tools/$CHANNEL/${td##*/}")
		echo "tool tree: ${td##*/}"
	done < <(find "$DIR/tools" -mindepth 1 -maxdepth 1 -type d | sort)
fi
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
KEEP_VERSIONS="${KEEP_VERSIONS:-10}"
"$here/publish-pages.sh" \
	-m "packages ($CHANNEL) @ $SHA${RUN:+ (run $RUN)}" \
	--channel "$CHANNEL" \
	--keys "$root/keys" \
	--keep "main/*=$KEEP_VERSIONS" \
	--keep "stable/*=$KEEP_VERSIONS" \
	"${pairs[@]}"

# A release also gets an archive copy on its GitHub release: one zip per
# architecture, the loose ddimension-feed.apk and the host tools. Those assets
# do not count against the 1 GB of the Pages site and they stay when the ten
# versions in the tree have rolled past. Not a repository to install from —
# see release-assets.sh. Only for a release tag, and never fatal: the packages
# are published at this point, a failed upload must not undo that.
if [ -n "$TAG" ] && [ "${RELEASE_ASSETS:-1}" = 1 ]; then
	"$here/release-assets.sh" --tag "$TAG" --repo "$REPO" --dir "$DIR" ||
		echo "::warning::release assets for $TAG failed; the feed itself is published"
fi
