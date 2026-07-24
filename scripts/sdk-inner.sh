#!/bin/sh
# Runs INSIDE the openwrt/sdk container (started by local-build.sh).
# Expects: /feed (this repo, ro), /logs (writable), $PACKAGES, $NPROC.
set -u
NPROC="${NPROC:-8}"
PACKAGES="${PACKAGES:?}"
cd /builder

# openwrt/sdk images are bootstrap images: setup.sh downloads the real SDK
# on first run. With a persistent /builder volume this happens only once.
if [ ! -x scripts/feeds ]; then
	./setup.sh >/logs/setup.log 2>&1 || {
		echo "SETUP FAILED"
		tail -5 /logs/setup.log
		exit 1
	}
fi

grep -q "src-link wwand /feed" feeds.conf.default 2>/dev/null ||
	echo "src-link wwand /feed" >>feeds.conf.default
./scripts/feeds update -a >/logs/feeds.log 2>&1
./scripts/feeds install -a -p wwand >>/logs/feeds.log 2>&1
make defconfig >/logs/defconfig.log 2>&1

# One batched build: all packages at once, keep-going so a single failure
# doesn't hide the others.
GOALS=""
for p in $PACKAGES; do GOALS="$GOALS package/feeds/wwand/$p/compile"; done
make -j"$NPROC" -k $GOALS >/logs/batch.log 2>&1

# Classify: a no-op recompile succeeds instantly for built packages.
rc=0
for p in $PACKAGES; do
	if make "package/feeds/wwand/$p/compile" >/dev/null 2>&1; then
		echo "PASS: $p"
	else
		rc=1
		echo "FAIL: $p"
		make -j1 "package/feeds/wwand/$p/compile" V=s >"/logs/vbuild-$p.log" 2>&1
		grep -E "error:|Error [0-9]+|ERROR:|undefined reference" "/logs/vbuild-$p.log" |
			head -8 | sed 's/^/  ERR /'
	fi
done
exit $rc
