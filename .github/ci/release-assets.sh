#!/bin/bash
# Attach what a release produced to its GitHub release — the archive copy of
# what the feed serves.
#
#   release-assets.sh --tag T --repo O/R [--dir DIR] [--images DIR]
#
#   --dir DIR     package trees as the publish job has them: DIR/<release>/<arch>/
#                 plus DIR/tools/<arch>/ for host tools. Each tree becomes one
#                 <release>-<arch>.zip, the versionless ddimension-feed.apk and
#                 the host tools are added as single files.
#   --images DIR  device images, flattened as publish-images stages them:
#                 DIR/<group>/<base>/<files>. Image files are uploaded one by
#                 one — their names already carry device and target.
#
# Why: GitHub release assets do not count against the 1 GB of a Pages site, they
# stay when the feed tree has long moved on, and a firmware image is exactly
# what a release page is for. What this is NOT is a repository to install from:
# the assets of a tag share one flat namespace, so wwand-1.6.9-r1.apk of eight
# architectures would collide, and apk resolves package files relative to its
# index anyway. Devices keep installing from gh-pages.
#
# Re-runnable: an asset of the same name is replaced, the release is created if
# it does not exist yet. Needs GH_TOKEN with contents:write (the publish jobs
# have it) and docker for zip (the apk-tools image, which the publish job
# already pulls).
set -euo pipefail

die() { echo "release-assets: $*" >&2; exit 1; }

TAG="" REPO="${GITHUB_REPOSITORY:-}" DIR="" IMAGES=""
while [ $# -gt 0 ]; do
	[ $# -ge 2 ] || die "$1 needs an argument"
	case "$1" in
	--tag) TAG="$2" ;;
	--repo) REPO="$2" ;;
	--dir) DIR="$2" ;;
	--images) IMAGES="$2" ;;
	*) die "unknown argument $1" ;;
	esac
	shift 2
done
[ -n "$TAG" ] || die "--tag is required"
[ -n "$REPO" ] || die "--repo (or GITHUB_REPOSITORY) is required"
[ -n "$DIR" ] || [ -n "$IMAGES" ] || die "nothing to attach: pass --dir and/or --images"
[ -n "${GH_TOKEN:-}" ] || die "GH_TOKEN is required (contents:write)"

API="https://api.github.com/repos/$REPO"
UPLOAD="https://uploads.github.com/repos/$REPO"
auth=(-H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json")

# curl, not gh: the runner image does not promise the gh CLI, and this is three
# plain REST calls. --fail-with-body would be the obvious flag and is NOT
# usable: the runners still carry curl 7.68 (Ubuntu 20.04), which does not know
# it and exits with "option --fail-with-body: is unknown" — that killed the
# first image publish that tried this (run 37214945447). So: body and status
# code in one request, status checked here, GitHub's error text kept.
api() {
	local out code body
	out="$(curl -sS -w '\n%{http_code}' "${auth[@]}" "$@")" || return 1
	code="${out##*$'\n'}"
	body="${out%$'\n'*}"
	case "$code" in
	2*) printf '%s' "$body"; return 0 ;;
	esac
	printf 'release-assets: HTTP %s: %s\n' "$code" "$(printf '%s' "$body" | tr -d '\n' | cut -c1-200)" >&2
	return 1
}

# The first "id" of the tags/<tag> response is the release id (author, assets
# and the rest come after it) — no jq needed, which the runner image does not
# promise either.
release_id() {
	local j
	# captured first, not piped: grep -m1 closes the pipe early and curl then
	# dies of EPIPE, which under pipefail would fail the whole call
	j="$(api "$API/releases/tags/$TAG" 2>/dev/null)" || return 1
	grep -m1 -oE '"id": *[0-9]+' <<<"$j" | grep -oE '[0-9]+'
}

rid="$(release_id || true)"
if [ -z "$rid" ]; then
	echo "release-assets: creating release $TAG"
	api -X POST "$API/releases" \
		-d "{\"tag_name\":\"$TAG\",\"name\":\"$TAG\",\"generate_release_notes\":false}" >/dev/null ||
		die "could not create the release for $TAG"
	rid="$(release_id || true)"
fi
[ -n "$rid" ] || die "no release id for $TAG"

# Existing assets, so a re-run replaces instead of failing on a duplicate name.
assets_json="$(api "$API/releases/$rid/assets?per_page=100")"
upload() {
	local file="$1" name="${2:-}" type old
	name="${name:-${file##*/}}"
	case "$name" in
	*.zip) type=application/zip ;;
	*.apk) type=application/octet-stream ;;
	*) type=application/octet-stream ;;
	esac
	# In the pretty-printed asset list "id" comes before "name" in each
	# object, so remember the last id seen and print it when the name matches.
	# again a here-string: the awk program exits at the first match, and a
	# printf writing into that pipe would fail with EPIPE under pipefail —
	# which under set -e ends the whole script, silently, mid-upload.
	old="$(awk -v want="$name" '
		match($0, /"id": *[0-9]+/) { id = substr($0, RSTART + 6, RLENGTH - 6); gsub(/[^0-9]/, "", id) }
		match($0, /"name": *"[^"]*"/) {
			n = substr($0, RSTART + 9, RLENGTH - 10)
			if (n == want && id != "") { print id; exit }
		}' <<<"$assets_json")"
	if [ -n "$old" ]; then
		api -X DELETE "$API/releases/assets/$old" >/dev/null ||
			echo "release-assets: could not remove the old $name, the upload will say so" >&2
	fi
	api -X POST -H "Content-Type: $type" --data-binary "@$file" \
		"$UPLOAD/releases/$rid/assets?name=$name" >/dev/null || die "upload of $name failed"
	echo "  $name ($(LC_ALL=C numfmt --to=iec --suffix=B "$(stat -c%s "$file")"))"
}

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

if [ -n "$DIR" ]; then
	[ -d "$DIR" ] || die "$DIR is not a directory"
	DIR="$(cd "$DIR" && pwd)"
	image="${APK_TOOLS_IMAGE:-image-registry.ddimension.net/myadmin/apk-tools:latest}"
	while IFS= read -r adb; do
		tree="${adb%/packages.adb}"
		arch="${tree##*/}"
		rel="${tree%/*}"
		rel="${rel##*/}"
		# zip in the container: the runner image does not promise it, and the
		# publish job pulls this image anyway. index.html stays out, it is a
		# property of the site, not of the tree.
		docker run --rm --user "$(id -u):$(id -g)" \
			-v "$(dirname "$tree"):/w:ro" -v "$work:/out" -w /w \
			"$image" zip -q -r -X "/out/$rel-$arch.zip" "$arch" -x '*/index.html' ||
			die "packing $rel/$arch failed"
		upload "$work/$rel-$arch.zip"
		rm -f "$work/$rel-$arch.zip"
		if [ -f "$tree/ddimension-feed.apk" ]; then
			upload "$tree/ddimension-feed.apk" "ddimension-feed-$rel-$arch.apk"
		fi
	done < <(find "$DIR" -name packages.adb | sort)
	# Host tools (the static rsim-card today): one file each, named by arch.
	if [ -d "$DIR/tools" ]; then
		while IFS= read -r f; do
			arch="$(basename "$(dirname "$f")")"
			upload "$f" "$(basename "$f")-$arch-static"
		done < <(find "$DIR/tools" -mindepth 2 -maxdepth 2 -type f ! -name 'index.html' ! -name '.published' | sort)
	fi
fi

if [ -n "$IMAGES" ]; then
	[ -d "$IMAGES" ] || die "$IMAGES is not a directory"
	# <group>/<base>/<file>: an image file name already carries target and
	# device, so <base>-<file> is unique. sha256sums does not — every group has
	# one — so that gets the group in front as well. (Learned the hard way: the
	# upload answers 422 when an asset of that name already exists.)
	while IFS= read -r f; do
		base="$(basename "$(dirname "$f")")"
		group="$(basename "$(dirname "$(dirname "$f")")")"
		case "$(basename "$f")" in
		sha256sums | *.buildinfo)
			upload "$f" "$group-$base-$(basename "$f")" ;;
		*)
			upload "$f" "$base-$(basename "$f")" ;;
		esac
	done < <(find "$IMAGES" -mindepth 3 -maxdepth 3 -type f \
		\( -name '*.bin' -o -name '*.itb' -o -name '*.img.gz' -o -name '*.manifest' -o -name 'sha256sums' \) | sort)
fi

echo "release-assets: $TAG is at https://github.com/$REPO/releases/tag/$TAG"
