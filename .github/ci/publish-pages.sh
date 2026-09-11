#!/bin/bash
# The one writer of the gh-pages branch — the site the feed is served from.
#
# Both workflows publish through here: build.yml the package trees of one
# channel, build-device-images.yml the device images. One layout, one index
# generator, one way onto the branch. A call replaces exactly the directories
# it is given and nothing else; whatever another run put there stays.
#
#   publish-pages.sh -m MSG [--channel C] [--keys DIR] [--remove DEST]... [SRC=DEST]...
#
#   SRC=DEST       replace DEST (relative to the site root) wholesale with the
#                  contents of SRC. Guarded, so a half-failed build cannot
#                  replace the last good state: a target under images/ needs
#                  at least one *sysupgrade* file in SRC, any other target a
#                  SRC/packages.adb. A pair that fails its guard is skipped.
#   --remove DEST  delete DEST, e.g. the tree of a release no longer built
#   --keys DIR     overlay DIR onto keys/: files are added or updated, never
#                  deleted — a device may know a key under an old name
#   --channel C    recorded in the .published stamps
#
# Env: GH_TOKEN (push credentials), GITHUB_REPOSITORY, GITHUB_SHA,
#      GITHUB_RUN_ID. PAGES_STAMP_SHA overrides the commit put into the stamps.
#      PAGES_REMOTE / PAGES_BRANCH / PAGES_ATTEMPTS / PAGES_BACKOFF ("MIN MAX"
#      seconds) exist for tests against a local bare repository.
#
# Concurrency. Several runs can publish at once: the main and the stable feed
# run, the image run. A concurrency group does not serialise them safely —
# GitHub keeps one pending run per group and cancels the older pending one, so
# a queued stable publish would silently be dropped. The push is a
# compare-and-swap instead: --force-with-lease against the commit the new site
# was built on. Whoever loses re-reads the branch, re-applies its change and
# tries again.
#
# There is no clean-up of the site root, on purpose. main and stable publish
# with the version of this script on their own branch; a keep-list in the older
# one would delete what the newer one added. Removing is explicit (--remove).
#
# The branch is a single orphan commit: the site is state, not history, and a
# history of package trees would only cost clone time. The commit is made in
# the clone of the current state, so a push carries new objects only.
#
# Every replaced directory gets a .published stamp,
#     <UTC ISO-8601 time> <channel> <source commit> <run id>
# The directory indexes take their dates from it — file mtimes are checkout
# times for everything this run did not write, so they would lie — and
# build-device-images.yml polls it to know when a commit's tree is live.
set -euo pipefail

die() { echo "publish-pages: $*" >&2; exit 1; }

MSG="" CHANNEL="-" KEYS=""
REMOVE=() PAIRS=()

need_arg() { [ "$2" -ge 2 ] || die "$1 needs an argument"; }
while [ $# -gt 0 ]; do
	case "$1" in
	-m) need_arg "$1" $#; MSG="$2"; shift 2 ;;
	--channel) need_arg "$1" $#; CHANNEL="$2"; shift 2 ;;
	--keys) need_arg "$1" $#; KEYS="$2"; shift 2 ;;
	--remove) need_arg "$1" $#; REMOVE+=("$2"); shift 2 ;;
	-h | --help) sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "$0"; exit 0 ;;
	-*) die "unknown option $1" ;;
	*=*) PAIRS+=("$1"); shift ;;
	*) die "expected SRC=DEST, got '$1'" ;;
	esac
done
[ -n "$MSG" ] || die "-m MSG is required"

# A destination is a plain relative path inside the site: no '..', no '.git',
# not the root itself.
check_dest() {
	local d="${1#./}"
	d="${d%/}"
	case "/$d/" in
	// | */../* | */./* | /.git/*) die "bad destination '$1'" ;;
	esac
	case "$d" in
	/*) die "destination must be relative: '$1'" ;;
	esac
	DEST="$d"
}

# ---- validate the request once, before touching the branch ------------------
ACCEPTED=() # "absolute-src=dest"
for pair in ${PAIRS[@]+"${PAIRS[@]}"}; do
	src="${pair%%=*}"
	check_dest "${pair#*=}"
	if [ ! -d "$src" ]; then
		echo "::warning::publish-pages: $src does not exist, $DEST keeps its published state"
		continue
	fi
	case "$DEST" in
	images/*)
		if [ -z "$(find "$src" -type f -name '*sysupgrade*' -print -quit)" ]; then
			echo "::warning::publish-pages: no sysupgrade image in $src, $DEST keeps its published state"
			continue
		fi
		;;
	*)
		if [ ! -f "$src/packages.adb" ]; then
			echo "::warning::publish-pages: no packages.adb in $src, $DEST keeps its published state"
			continue
		fi
		;;
	esac
	ACCEPTED+=("$(cd "$src" && pwd)=$DEST")
done
REMOVE_OK=()
for d in ${REMOVE[@]+"${REMOVE[@]}"}; do
	check_dest "$d"
	REMOVE_OK+=("$DEST")
done
if [ -n "$KEYS" ]; then
	[ -d "$KEYS" ] || die "--keys $KEYS is not a directory"
	KEYS="$(cd "$KEYS" && pwd)"
fi
if [ ${#ACCEPTED[@]} -eq 0 ] && [ ${#REMOVE_OK[@]} -eq 0 ] && [ -z "$KEYS" ]; then
	echo "publish-pages: nothing to publish"
	exit 0
fi

REMOTE="${PAGES_REMOTE:-https://github.com/${GITHUB_REPOSITORY:?set GITHUB_REPOSITORY or PAGES_REMOTE}.git}"
BRANCH="${PAGES_BRANCH:-gh-pages}"
ATTEMPTS="${PAGES_ATTEMPTS:-10}"
read -r BACKOFF_MIN BACKOFF_MAX <<<"${PAGES_BACKOFF:-10 40}"
STAMP_SHA="${PAGES_STAMP_SHA:-${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}}"
RUN_ID="${GITHUB_RUN_ID:-local}"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Credentials through environment-scoped git config: not on any command line
# and not in any .git/config. A token in the clone URL — how this used to be
# done — is stored in the clone's config, which on a persistent self-hosted
# workspace outlives the job.
if [ -n "${GH_TOKEN:-}" ]; then
	export GIT_CONFIG_COUNT=1
	export GIT_CONFIG_KEY_0="http.https://github.com/.extraheader"
	GIT_CONFIG_VALUE_0="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GH_TOKEN" | base64 -w0)"
	export GIT_CONFIG_VALUE_0
fi
export GIT_AUTHOR_NAME="ddimension ci" GIT_AUTHOR_EMAIL="ci@ddimension.net"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/publish-pages.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
SITE="$WORK/site"
OLD=""

# ---- read the current state ------------------------------------------------
fetch_site() {
	if [ -d "$SITE/.git" ] && git -C "$SITE" rev-parse -q --verify HEAD >/dev/null; then
		git -C "$SITE" fetch -q --depth 1 origin "$BRANCH"
		OLD="$(git -C "$SITE" rev-parse FETCH_HEAD)"
		git -C "$SITE" reset -q --hard "$OLD"
		git -C "$SITE" clean -qfdx
		return
	fi
	rm -rf "$SITE"
	local rc=0
	git ls-remote --exit-code --heads "$REMOTE" "$BRANCH" >/dev/null || rc=$?
	case "$rc" in
	0)
		git clone -q --depth 1 --single-branch --branch "$BRANCH" "$REMOTE" "$SITE"
		OLD="$(git -C "$SITE" rev-parse HEAD)"
		;;
	2) # the branch does not exist yet: start from nothing
		git init -q "$SITE"
		git -C "$SITE" remote add origin "$REMOTE"
		OLD=""
		;;
	*) die "cannot read $REMOTE" ;;
	esac
}

# ---- change it -------------------------------------------------------------
stamp() {
	printf '%s %s %s %s\n' "$NOW" "$CHANNEL" "$STAMP_SHA" "$RUN_ID" >"$1/.published"
}

apply_changes() {
	local d pair src dest f keys_changed=0
	for d in ${REMOVE_OK[@]+"${REMOVE_OK[@]}"}; do
		[ -e "$SITE/$d" ] || continue
		rm -rf "${SITE:?}/$d"
		echo "removed   $d"
	done
	for pair in ${ACCEPTED[@]+"${ACCEPTED[@]}"}; do
		src="${pair%%=*}"
		dest="${pair#*=}"
		rm -rf "${SITE:?}/$dest"
		mkdir -p "$SITE/$dest"
		cp -R "$src/." "$SITE/$dest/"
		stamp "$SITE/$dest"
		echo "published $dest"
	done
	if [ -n "$KEYS" ]; then
		mkdir -p "$SITE/keys"
		for f in "$KEYS"/*; do
			[ -f "$f" ] || continue
			cmp -s "$f" "$SITE/keys/${f##*/}" && continue
			cp "$f" "$SITE/keys/"
			keys_changed=1
			echo "key       keys/${f##*/}"
		done
		if [ "$keys_changed" = 1 ] || [ ! -e "$SITE/keys/.published" ]; then
			stamp "$SITE/keys"
		fi
	fi
	touch "$SITE/.nojekyll" # serve as-is: no Jekyll, dotfiles included
	write_indexes
}

# ---- directory indexes (GitHub Pages serves no listings) -------------------
# Dates come from the .published stamps: a file is as old as the publish of the
# nearest stamped directory at or above it, a directory as new as the newest
# stamp inside it. Dotfiles are not listed.
stamp_time() {
	local t _
	[ -r "$1" ] && read -r t _ <"$1" && printf '%s' "$t"
	return 0
}
file_time() {
	local d="$1"
	while :; do
		if [ -r "$d/.published" ]; then
			stamp_time "$d/.published"
			return 0
		fi
		[ "$d" = "$SITE" ] && return 0
		d="${d%/*}"
	done
}
dir_time() {
	find "$1" -type f -name .published -exec cat {} + 2>/dev/null |
		awk '$1 ~ /^[0-9]{4}-/ { print $1 }' | sort | tail -n 1
}
day() { printf '%s' "${1%%T*}"; }
hm() {
	local x="${1#*T}"
	printf '%s' "${x:0:5}"
}

ROOT_NOTE='<p>Package feed of <a href="https://github.com/ddimension/openwrt-repo">ddimension/openwrt-repo</a>:
<code>stable/</code> = releases, <code>main/</code> = development, each as
<code>&lt;release&gt;/&lt;arch&gt;/</code>. The <code>&lt;release&gt;/</code> trees at the top
mirror <code>stable/</code> for devices set up before the channels existed.
Device images are under <code>images/</code>, signing keys under <code>keys/</code>.</p>'

write_index() {
	local d="$1" rel e n t ft
	rel="${d#"$SITE"}"
	rel="${rel#/}"
	ft="$(file_time "$d")"
	{
		printf '<!doctype html><meta charset="utf-8">'
		printf '<title>openwrt-repo/%s</title>' "$rel"
		printf '<style>body{font:14px/1.5 monospace;margin:2em}'
		printf 'td{padding:0 1.5em 0 0}td.n{text-align:right}'
		printf 'th{text-align:left;padding:0 1.5em .3em 0;border-bottom:1px solid #ccc}</style>'
		printf '<h2>openwrt-repo/%s</h2>' "$rel"
		[ -z "$rel" ] && printf '%s' "$ROOT_NOTE"
		printf '<table><tr><th>Name</th><th>Size</th><th>Date</th><th>Time (UTC)</th></tr>'
		[ -n "$rel" ] && printf '<tr><td><a href="../">../</a></td><td></td><td></td><td></td></tr>'
		for e in "$d"/*; do
			[ -e "$e" ] || continue
			n="${e##*/}"
			[ "$n" = index.html ] && continue
			if [ -d "$e" ]; then
				t="$(dir_time "$e")"
				printf '<tr><td><a href="%s/">%s/</a></td><td></td><td>%s</td><td>%s</td></tr>' \
					"$n" "$n" "$(day "$t")" "$(hm "$t")"
			else
				printf '<tr><td><a href="%s">%s</a></td><td class="n">%s</td><td>%s</td><td>%s</td></tr>' \
					"$n" "$n" "$(LC_ALL=C numfmt --to=iec --suffix=B "$(stat -c%s "$e")")" \
					"$(day "$ft")" "$(hm "$ft")"
			fi
		done
		printf '</table>\n'
	} >"$d/index.html"
}

write_indexes() {
	local d n=0
	while IFS= read -r d; do
		write_index "$d"
		n=$((n + 1))
	done < <(find "$SITE" -path "$SITE/.git" -prune -o -type d -print)
	echo "indexed   $n directories"
}

# ---- compare-and-swap onto the branch --------------------------------------
# Returns 0 when published (or when there is nothing to change), 1 when the
# push was refused. Every step checks for itself: a function called as an if
# condition runs without set -e.
commit_and_push() {
	local tree commit
	git -C "$SITE" add -A || return 1
	if [ -n "$OLD" ] && git -C "$SITE" diff --cached --quiet "$OLD"; then
		echo "publish-pages: site unchanged, nothing to push"
		return 0
	fi
	tree="$(git -C "$SITE" write-tree)" || return 1
	commit="$(git -C "$SITE" commit-tree "$tree" -m "$MSG")" || return 1
	git -C "$SITE" push -q --force-with-lease="refs/heads/$BRANCH:$OLD" \
		origin "$commit:refs/heads/$BRANCH" || return 1
	echo "publish-pages: $BRANCH ${OLD:0:12} -> ${commit:0:12}"
}

for attempt in $(seq 1 "$ATTEMPTS"); do
	fetch_site
	apply_changes
	if commit_and_push; then
		if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
			{
				echo "### gh-pages: $MSG"
				for pair in ${ACCEPTED[@]+"${ACCEPTED[@]}"}; do echo "- published \`${pair#*=}\`"; done
				for d in ${REMOVE_OK[@]+"${REMOVE_OK[@]}"}; do echo "- removed \`$d\`"; done
			} >>"$GITHUB_STEP_SUMMARY"
		fi
		exit 0
	fi
	[ "$attempt" -lt "$ATTEMPTS" ] || break
	delay=$((BACKOFF_MIN + RANDOM % (BACKOFF_MAX - BACKOFF_MIN + 1)))
	echo "publish-pages: push refused (branch moved meanwhile?), retry $((attempt + 1))/$ATTEMPTS in ${delay}s"
	sleep "$delay"
done
die "gave up after $ATTEMPTS attempts"
