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
#      GITHUB_RUN_ID. PAGES_STAMP_SHA overrides the commit put into the stamps,
#      PAGES_SITE_URL the absolute site address shown on the start page.
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
#
# The start page lists, per architecture, the trees of both channels and the
# versionless ddimension-feed.apk in each (build.yml puts it there), built
# from what is actually on the site — a link on it never points at nothing.
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
SITE_URL="${PAGES_SITE_URL:-https://ddimension.github.io/openwrt-repo}"

# Credentials through environment-scoped git config: not on any command line
# and not in any .git/config. A token in the clone URL — how this used to be
# done — is stored in the clone's config, which on a persistent self-hosted
# workspace outlives the job.
#
# The first, empty entry clears the header list before the second sets ours.
# Without it git sends two Authorization headers whenever another config
# already carries one — actions/checkout leaves exactly that in the workspace
# repository (persist-credentials) — and GitHub answers "Duplicate header",
# HTTP 400. The script also leaves the caller's directory right away (below),
# so no repository config applies to its git calls at all.
if [ -n "${GH_TOKEN:-}" ]; then
	export GIT_CONFIG_COUNT=2
	export GIT_CONFIG_KEY_0="http.https://github.com/.extraheader" GIT_CONFIG_VALUE_0=""
	export GIT_CONFIG_KEY_1="http.https://github.com/.extraheader"
	GIT_CONFIG_VALUE_1="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GH_TOKEN" | base64 -w0)"
	export GIT_CONFIG_VALUE_1
fi
export GIT_AUTHOR_NAME="ddimension ci" GIT_AUTHOR_EMAIL="ci@ddimension.net"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/publish-pages.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK" # out of the caller's repository (see above); every path from here is absolute
SITE="$WORK/site"
OLD=""

# ---- read the current state ------------------------------------------------
# Returns 1 on any network or git failure, so the caller can retry: it runs as
# an if condition, where set -e does not apply.
fetch_site() {
	if [ -d "$SITE/.git" ] && git -C "$SITE" rev-parse -q --verify HEAD >/dev/null; then
		git -C "$SITE" fetch -q --depth 1 origin "$BRANCH" || return 1
		OLD="$(git -C "$SITE" rev-parse FETCH_HEAD)" || return 1
		git -C "$SITE" reset -q --hard "$OLD" || return 1
		git -C "$SITE" clean -qfdx || return 1
		return 0
	fi
	rm -rf "$SITE"
	local rc=0
	git ls-remote --exit-code --heads "$REMOTE" "$BRANCH" >/dev/null || rc=$?
	case "$rc" in
	0)
		git clone -q --depth 1 --single-branch --branch "$BRANCH" "$REMOTE" "$SITE" || return 1
		OLD="$(git -C "$SITE" rev-parse HEAD)" || return 1
		;;
	2) # the branch does not exist yet: start from nothing
		git init -q "$SITE" && git -C "$SITE" remote add origin "$REMOTE" || return 1
		OLD=""
		;;
	*) return 1 ;;
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
		awk '$1 ~ /^[0-9][0-9][0-9][0-9]-/ { print $1 }' | sort | tail -n 1
}
day() { printf '%s' "${1%%T*}"; }
hm() {
	local x="${1#*T}"
	printf '%s' "${x:0:5}"
}

# One stylesheet for every page: readable in light and dark mode, monospace
# like a directory listing should be.
CSS=':root{color-scheme:light dark;--fg:#1f2328;--bg:#fff;--mut:#59636e;--line:#d1d9e0;--acc:#0969da;--hi:rgba(127,127,127,.09)}
@media(prefers-color-scheme:dark){:root{--fg:#e6edf3;--bg:#0d1117;--mut:#9198a1;--line:#3d444d;--acc:#4493f8}}
body{font:14px/1.55 ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;margin:2em auto;max-width:78em;padding:0 1.2em;color:var(--fg);background:var(--bg)}
a{color:var(--acc);text-decoration:none}a:hover{text-decoration:underline}
h1{font-size:1.25em;font-weight:600;border-bottom:1px solid var(--line);padding-bottom:.4em}
h2{font-size:1.05em;font-weight:600;margin-top:2em}
p{color:var(--mut);max-width:62em}
code,pre{background:var(--hi);border-radius:4px}code{padding:.1em .3em}pre{padding:.8em 1em;overflow-x:auto}
table{border-collapse:collapse;margin:.5em 0}
th,td{padding:.3em 1.4em .3em 0;text-align:left;vertical-align:top}
th{border-bottom:1px solid var(--line);color:var(--mut);font-weight:600}
td.n{text-align:right}tr:hover td{background:var(--hi)}
.dim{color:var(--mut)}'

# openwrt-repo / stable / openwrt-25.12 / x86_64, each part a link
breadcrumb() {
	local rel="$1" up="" i depth=0 parts=() out
	[ -n "$rel" ] && IFS=/ read -r -a parts <<<"$rel" && depth=${#parts[@]}
	for ((i = 0; i < depth; i++)); do up+="../"; done
	out="<a href=\"${up:-./}\">openwrt-repo</a>"
	for ((i = 0; i < depth; i++)); do
		up="${up#../}"
		out+=" / <a href=\"${up:-./}\">${parts[i]}</a>"
	done
	printf '%s' "$out"
}

# The start page: how to set a device up, and per architecture the trees of
# both channels with the ddimension-feed.apk in each — only what exists.
landing() {
	local rels archs r a ch d cell
	# if, not `test && find`: under pipefail a loop whose last test fails makes
	# the whole command substitution fail, and set -e ends the script without a
	# word — which is what the very first publish did, when main/ did not exist.
	rels="$(for ch in stable main; do
		if [ -d "$SITE/$ch" ]; then find "$SITE/$ch" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'; fi
	done | sort -u)" # openwrt-25.12 … before snapshot, like README.md
	[ -n "$rels" ] || return 0
	archs="$(for ch in stable main; do for r in $rels; do
		if [ -d "$SITE/$ch/$r" ]; then find "$SITE/$ch/$r" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'; fi
	done; done | sort -u)"
	printf '<h2>Set up a device</h2>'
	printf '<p>Install <code>ddimension-feed</code> once, by name, from the tree that matches the device —'
	printf ' it carries the feed address and the signing key, and keeps both current with <code>apk upgrade</code>:</p>'
	printf '<pre>apk --allow-untrusted \\\n  -X %s/stable/&lt;release&gt;/&lt;arch&gt;/packages.adb \\\n  add ddimension-feed\napk update\napk add wwand luci-app-wwand</pre>' "$SITE_URL"
	printf '<p><b>stable</b> = releases, <b>main</b> = development. A downloaded <code>ddimension-feed.apk</code>'
	printf ' works too: <code>apk add --allow-untrusted ./ddimension-feed.apk &amp;&amp; apk update &amp;&amp; apk add ddimension-feed</code>'
	printf ' — the last step turns the file install into a normal one, otherwise apk keeps it pinned and never upgrades it.'
	printf ' Details: <a href="https://github.com/ddimension/openwrt-repo#how-tos">README</a>.</p>'
	printf '<h2>Feeds</h2><table><tr><th>Arch</th>'
	for ch in stable main; do for r in $rels; do printf '<th>%s · %s</th>' "$ch" "$r"; done; done
	printf '</tr>'
	for a in $archs; do
		printf '<tr><td>%s</td>' "$a"
		for ch in stable main; do for r in $rels; do
			d="$ch/$r/$a"
			if [ -f "$SITE/$d/packages.adb" ]; then
				cell="<a href=\"$d/\">tree</a>"
				[ -f "$SITE/$d/ddimension-feed.apk" ] &&
					cell+=" · <a href=\"$d/ddimension-feed.apk\">ddimension-feed.apk</a>"
			else
				cell='<span class="dim">—</span>'
			fi
			printf '<td>%s</td>' "$cell"
		done; done
		printf '</tr>'
	done
	printf '</table>'
	printf '<p>The top-level <code>&lt;release&gt;/</code> trees mirror <code>stable/</code> for devices set up'
	printf ' before the channels existed. Device images: <a href="images/">images/</a>, signing keys:'
	printf ' <a href="keys/">keys/</a>. Source: <a href="https://github.com/ddimension/openwrt-repo">ddimension/openwrt-repo</a>.</p>'
	printf '<h2>Everything</h2>'
}

write_index() {
	local d="$1" rel e n t ft
	rel="${d#"$SITE"}"
	rel="${rel#/}"
	ft="$(file_time "$d")"
	{
		printf '<!doctype html><meta charset="utf-8">'
		printf '<meta name="viewport" content="width=device-width,initial-scale=1">'
		printf '<title>openwrt-repo/%s</title><style>%s</style>' "$rel" "$CSS"
		printf '<h1>%s</h1>' "$(breadcrumb "$rel")"
		[ -z "$rel" ] && landing
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
	if ! fetch_site; then
		why="could not read $BRANCH from $REMOTE"
	else
		apply_changes
		why="push refused (branch moved meanwhile?)"
	fi
	if [ "$why" != "${why#push}" ] && commit_and_push; then
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
	echo "publish-pages: $why, retry $((attempt + 1))/$ATTEMPTS in ${delay}s"
	sleep "$delay"
done
die "gave up after $ATTEMPTS attempts"
