#!/bin/bash
# Pull the sysupgrade configuration backup off every AP of the fleet.
#
#   scripts/backup-ap-configs.sh <target-dir> [ap ...]
#
# The archive is exactly what `sysupgrade -b` writes, the same one LuCI's
# "Generate archive" hands out. It is fetched with `sysupgrade -b -`, which
# streams the tarball to stdout and forces VERBOSE=0 so no status line ends up
# inside it; the stream is piped straight into a local file. Nothing is written
# on the AP itself, so this also works on a full flash.
#
# With no AP named on the command line the list comes from the MQTT broker:
# apman publishes properties/system/board retained for every AP it manages, so
# subscribing to that topic pattern enumerates the fleet with no list to keep
# up to date. Name the broker with -b or in APMAN_BROKER.
#
# Examples:
#   scripts/backup-ap-configs.sh /srv/backup -b mqtt.example.net
#   scripts/backup-ap-configs.sh /srv/backup ap-attic ap-outdoor
#   scripts/backup-ap-configs.sh /srv/backup -f aps.txt --domain .lan
set -u

usage() {
	cat <<'EOF'
Usage: backup-ap-configs.sh <target-dir> [ap ...]

Fetches the sysupgrade config backup ("Generate archive") from each AP over
ssh and stores it as <target-dir>/backup-<ap>-<timestamp>.tar.gz.

Options:
  -b, --broker HOST     MQTT broker to enumerate the fleet from
                        [$APMAN_BROKER]
  -p, --prefix PREFIX   apman topic prefix                     [apman/]
  -f, --from-file FILE  read AP names from FILE, one per line
                        ('#' comments and blank lines ignored)
  -u, --user USER       ssh user                               [root]
  -d, --domain SUFFIX   appended to each name for ssh (e.g. .lan)
  -t, --timeout SEC     ssh connect timeout                    [10]
  -w, --wait SEC        how long to collect retained MQTT topics [3]
  -l, --list            only print the AP list, fetch nothing
  -h, --help            this help

Env: APMAN_BROKER, APMAN_MQTT_OPTS (extra mosquitto_sub args, e.g. auth),
     SSH_CMD (default: ssh)

Exit status is non-zero if any AP failed; the others are still fetched.
EOF
	exit "${1:-0}"
}

BROKER="${APMAN_BROKER:-}"
PREFIX="apman/"
FROM_FILE=""
SSH_USER="root"
DOMAIN=""
CONNECT_TIMEOUT=10
MQTT_WAIT=3
LIST_ONLY=0
TARGET=""
APS=()

while [ $# -gt 0 ]; do
	case "$1" in
	-b | --broker) BROKER="$2"; shift 2 ;;
	-p | --prefix) PREFIX="$2"; shift 2 ;;
	-f | --from-file) FROM_FILE="$2"; shift 2 ;;
	-u | --user) SSH_USER="$2"; shift 2 ;;
	-d | --domain) DOMAIN="$2"; shift 2 ;;
	-t | --timeout) CONNECT_TIMEOUT="$2"; shift 2 ;;
	-w | --wait) MQTT_WAIT="$2"; shift 2 ;;
	-l | --list) LIST_ONLY=1; shift ;;
	-h | --help) usage ;;
	--) shift; break ;;
	-*) echo "Unknown option: $1" >&2; usage 1 ;;
	*)
		if [ -z "$TARGET" ]; then TARGET="$1"; else APS+=("$1"); fi
		shift ;;
	esac
done
while [ $# -gt 0 ]; do APS+=("$1"); shift; done

[ -n "$TARGET" ] || { echo "ERROR: no target directory given." >&2; usage 1; }

SSH_CMD="${SSH_CMD:-ssh}"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout="$CONNECT_TIMEOUT"
	-o LogLevel=ERROR)

# ---- AP list: arguments, then a file, then the broker ----------------------
if [ -n "$FROM_FILE" ]; then
	[ -r "$FROM_FILE" ] || { echo "ERROR: cannot read $FROM_FILE" >&2; exit 1; }
	while read -r line; do
		line="${line%%#*}"
		line="$(echo "$line" | tr -d '[:space:]')"
		[ -n "$line" ] && APS+=("$line")
	done <"$FROM_FILE"
fi

if [ ${#APS[@]} -eq 0 ]; then
	[ -n "$BROKER" ] || {
		echo "ERROR: no APs given and no MQTT broker to ask (-b/APMAN_BROKER)." >&2
		exit 1
	}
	command -v mosquitto_sub >/dev/null 2>&1 || {
		echo "ERROR: mosquitto_sub not found — name the APs instead." >&2
		exit 1
	}
	echo ">> enumerating the fleet on $BROKER (${MQTT_WAIT}s of retained topics)"
	# -F '%t' prints the topic only; the AP name is the segment after 'ap/'
	while read -r name; do
		[ -n "$name" ] && APS+=("$name")
	done < <(mosquitto_sub -h "$BROKER" ${APMAN_MQTT_OPTS:-} \
		-t "${PREFIX}ap/+/properties/system/board" \
		-F '%t' -W "$MQTT_WAIT" 2>/dev/null |
		awk -F/ '{ for (i = 1; i < NF; i++) if ($i == "ap") { print $(i + 1); break } }' |
		sort -u)
	[ ${#APS[@]} -gt 0 ] || {
		echo "ERROR: the broker returned no AP. Wrong prefix, or nothing retained?" >&2
		exit 1
	}
fi

if [ "$LIST_ONLY" = 1 ]; then
	printf '%s\n' "${APS[@]}"
	exit 0
fi

mkdir -p "$TARGET" || exit 1
STAMP="$(date +%Y%m%d-%H%M%S)"

echo ">> ${#APS[@]} AP(s) -> $TARGET"

ok=0
failed=()
for ap in "${APS[@]}"; do
	host="${ap}${DOMAIN}"
	out="$TARGET/backup-$ap-$STAMP.tar.gz"
	tmp="$out.part"
	err="$(mktemp)"

	printf '%-28s ' "$ap"
	if ! "$SSH_CMD" "${SSH_OPTS[@]}" "$SSH_USER@$host" 'sysupgrade -b -' \
		>"$tmp" 2>"$err"; then
		echo "FAILED ($(head -n1 "$err" | cut -c1-60))"
		rm -f "$tmp" "$err"
		failed+=("$ap")
		continue
	fi

	# A truncated transfer or a shell error on the far side still leaves a
	# file behind, so the archive has to prove itself before it is kept.
	if ! gzip -t "$tmp" 2>/dev/null || ! tar tzf "$tmp" >/dev/null 2>&1; then
		echo "FAILED (no valid archive received)"
		rm -f "$tmp" "$err"
		failed+=("$ap")
		continue
	fi
	if ! tar tzf "$tmp" 2>/dev/null | grep -q '^etc/config/'; then
		echo "FAILED (archive carries no etc/config)"
		rm -f "$tmp" "$err"
		failed+=("$ap")
		continue
	fi

	mv "$tmp" "$out"
	rm -f "$err"
	files="$(tar tzf "$out" 2>/dev/null | grep -cv '/$')"
	size="$(du -h "$out" | cut -f1)"
	echo "ok  ${files} files, ${size}  ${out##*/}"
	ok=$((ok + 1))
done

echo ">> $ok of ${#APS[@]} saved in $TARGET"
if [ ${#failed[@]} -gt 0 ]; then
	echo ">> failed: ${failed[*]}" >&2
	exit 1
fi
