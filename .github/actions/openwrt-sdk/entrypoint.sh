#!/bin/bash

set -ef

GROUP=

group() {
	endgroup
	echo "::group::  $1"
	GROUP=1
}

endgroup() {
	if [ -n "$GROUP" ]; then
		echo "::endgroup::"
	fi
	GROUP=
}

trap 'endgroup' ERR

group "bash setup.sh"
# snapshot containers don't ship with the SDK to save bandwidth
# run setup.sh to download and extract the SDK
[ ! -f setup.sh ] || bash setup.sh
endgroup

# --- persistente, arch-uebergreifend geteilte Caches -----------------------
# Named Volumes werden vom Runner als -v /dl bzw. -v /ccache eingehaengt (und dort
# auf uid 1000 gechownt). Fehlen die Mounts, laeuft alles unveraendert weiter.
#   dl/     : Quell-Tarballs (arch-unabhaengig) -> ein geteiltes Volume
#   ccache  : Compile-Cache (ccache keyt nach Compiler/Flags, kollidiert nicht)
if [ -d /dl ]; then
	rm -rf dl && ln -s /dl dl
fi
if [ -d /ccache ]; then
	# OpenWrt ignoriert eine CCACHE_DIR-Env und nutzt $(TOPDIR)/.ccache (rules.mk).
	# Also .ccache auf das Volume symlinken -- analog zu dl.
	echo "CONFIG_CCACHE=y" >> .config
	rm -rf .ccache && ln -s /ccache .ccache
fi
# ---------------------------------------------------------------------------

FEEDNAME="${FEEDNAME:-action}"
# Build requested packages by default, otherwise just check
BUILD="${BUILD:-1}"
BUILD_LOG="${BUILD_LOG:-1}"

if [ -n "$KEY_BUILD" ]; then
	echo "$KEY_BUILD" > key-build
	CONFIG_SIGNED_PACKAGES="y"
fi

if [ -n "$PRIVATE_KEY" ]; then
	echo "$PRIVATE_KEY" > private-key.pem
	CONFIG_SIGNED_PACKAGES="y"
fi

if [ -z "$NO_DEFAULT_FEEDS" ]; then
	sed \
		-e 's,https://git.openwrt.org/feed/,https://github.com/openwrt/,' \
		-e 's,https://git.openwrt.org/openwrt/,https://github.com/openwrt/,' \
		-e 's,https://git.openwrt.org/project/,https://github.com/openwrt/,' \
		feeds.conf.default > feeds.conf
fi

echo "src-link $FEEDNAME /feed/" >> feeds.conf

ALL_CUSTOM_FEEDS="$FEEDNAME "
#shellcheck disable=SC2153
for EXTRA_FEED in $EXTRA_FEEDS; do
	echo "$EXTRA_FEED" | tr '|' ' ' >> feeds.conf
	ALL_CUSTOM_FEEDS+="$(echo "$EXTRA_FEED" | cut -d'|' -f2) "
done

group "feeds.conf"
cat feeds.conf
endgroup

group "feeds update -a"
./scripts/feeds update -a
endgroup

group "make defconfig"
# Fresh selection on every run: a leftover .config (persistent volume or
# reused builder) keeps old CONFIG_PACKAGE_* selections alive — defconfig
# only normalizes, it never deselects. That is how stray packages (e.g.
# perl) end up in a per-package build.
rm -f .config .config.old
make defconfig

# EXTRA_CONFIG: build-time symbols the caller wants set, one "CONFIG_X=y" per
# whitespace-separated word. Appended AFTER defconfig (the rm above would eat
# anything written earlier) and followed by a second defconfig so Kconfig
# resolves the dependencies the new symbols pull in.
if [ -n "$EXTRA_CONFIG" ]; then
	for OPT in $EXTRA_CONFIG; do
		echo "$OPT" >> .config
	done
	make defconfig

	# Verify every symbol SURVIVED. defconfig drops a symbol whose Kconfig is
	# not in the tree or whose dependencies are unmet, and it does so in
	# silence — a package-scoped option (one inside `define Package/x/config`,
	# `depends on PACKAGE_x`) is dropped unless CONFIG_PACKAGE_x=y is set too.
	# That failure mode is invisible in the build log and produces a package
	# built with the DEFAULT, which is why this check is fatal rather than a
	# warning: a silently ignored build option is worse than a failed build.
	MISSING=""
	for OPT in $EXTRA_CONFIG; do
		grep -qxF "$OPT" .config || MISSING="$MISSING $OPT"
	done

	if [ -n "$MISSING" ]; then
		echo "ERROR: EXTRA_CONFIG did not survive defconfig:$MISSING" >&2
		echo "       (a package-scoped symbol also needs its CONFIG_PACKAGE_* selected)" >&2
		exit 1
	fi
fi
endgroup

if [ -z "$PACKAGES" ]; then
	# compile all packages in feed
	for FEED in $ALL_CUSTOM_FEEDS; do
		group "feeds install -p $FEED -f -a"
		./scripts/feeds install -p "$FEED" -f -a
		endgroup
	done

	RET=0

	make \
		BUILD_LOG="$BUILD_LOG" \
		CONFIG_SIGNED_PACKAGES="$CONFIG_SIGNED_PACKAGES" \
		IGNORE_ERRORS="$IGNORE_ERRORS" \
		CONFIG_AUTOREMOVE=y \
		V="$V" \
		-j "$(nproc)" || RET=$?
else
	# compile specific packages with checks
	for PKG in $PACKAGES; do
		for FEED in $ALL_CUSTOM_FEEDS; do
			group "feeds install -p $FEED -f $PKG"
			./scripts/feeds install -p "$FEED" -f "$PKG"
			endgroup
		done

		group "make package/$PKG/download"
		make \
			BUILD_LOG="$BUILD_LOG" \
			IGNORE_ERRORS="$IGNORE_ERRORS" \
			"package/$PKG/download" V=s
		endgroup

		[ "$BUILD" = '1' ] && group "make package/$PKG/check"
		make \
			BUILD_LOG="$BUILD_LOG" \
			IGNORE_ERRORS="$IGNORE_ERRORS" \
			"package/$PKG/check" V=s 2>&1 | \
				tee logtmp

		RET=${PIPESTATUS[0]}
		[ "$BUILD" = '1' ] && endgroup

		if [ "$RET" -ne 0 ]; then
			echo 'Package check failed'
			exit "$RET"
		elif [ "$BUILD" = 0 ]; then
			echo 'Package check successful'
		fi

		badhash_msg="HASH does not match "
		badhash_msg+="|HASH uses deprecated hash,"
		badhash_msg+="|HASH is missing,"
		if grep -qE "$badhash_msg" logtmp; then
			echo "Package HASH check failed"
			exit 1
		fi

		PATCHES_DIR=$(find /feed -path "*/$PKG/patches")
		if [ -d "$PATCHES_DIR" ] && [ -z "$NO_REFRESH_CHECK" ]; then
			[ "$BUILD" = '1' ] && group "make package/$PKG/refresh"
			make \
				BUILD_LOG="$BUILD_LOG" \
				IGNORE_ERRORS="$IGNORE_ERRORS" \
				"package/$PKG/refresh" V=s
			[ "$BUILD" = '1' ] && endgroup

			if ! git -C "$PATCHES_DIR" diff --quiet -- .; then
				echo "Dirty patches detected, please refresh and review the diff"
				git -C "$PATCHES_DIR" checkout -- .
				exit 1
			fi

			group "make package/$PKG/clean"
			make \
				BUILD_LOG="$BUILD_LOG" \
				IGNORE_ERRORS="$IGNORE_ERRORS" \
				"package/$PKG/clean" V=s
			endgroup
		fi

		FILES_DIR=$(find /feed -path "*/$PKG/files")
		if [ -d "$FILES_DIR" ] && [ -z "$NO_SHFMT_CHECK" ]; then
			find "$FILES_DIR" -name "*.init" -exec shfmt -w -sr -s '{}' \;
			if ! git -C "$FILES_DIR" diff --quiet -- .; then
				echo "init script must be formatted. Please run through shfmt -w -sr -s"
				git -C "$FILES_DIR" checkout -- .
				exit 1
			fi
		fi
	done

	if [ "$BUILD" != '1' ]; then
		echo 'Skipping build'
		exit
	fi

	make \
		-f .config \
		-f tmp/.packagedeps \
		-f <(echo "\$(info \$(sort \$(package-y) \$(package-m)))"; echo -en "a:\n\t@:") \
			| tr ' ' '\n' > enabled-package-subdirs.txt

	RET=0

	for PKG in $PACKAGES; do
		if ! grep -m1 -qE "(^|/)$PKG$" enabled-package-subdirs.txt; then
			echo "::warning file=$PKG::Skipping $PKG due to unsupported architecture"
			continue
		fi

		make \
			BUILD_LOG="$BUILD_LOG" \
			IGNORE_ERRORS="$IGNORE_ERRORS" \
			CONFIG_AUTOREMOVE=y \
			V="$V" \
			-j "$(nproc)" \
			"package/$PKG/compile" || {
				RET=$?
				break
			}
	done
fi

if [ "$INDEX" = '1' ];then
	group "make package/index"
	make \
		CONFIG_SIGNED_PACKAGES="$CONFIG_SIGNED_PACKAGES" \
		V=s \
		package/index
	endgroup
fi

# /artifacts is a volume (different filesystem) and may hold leftovers from
# a previous job — plain `mv` refuses a non-empty target across devices.
# Clear and copy instead.
if [ -d bin/ ]; then
	rm -rf /artifacts/bin
	cp -a bin /artifacts/
	rm -rf bin/
fi

if [ -d logs/ ]; then
	rm -rf /artifacts/logs
	cp -a logs /artifacts/
	rm -rf logs/
fi

exit "$RET"
