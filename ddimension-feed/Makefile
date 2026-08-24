#
# The feed's own address and signing key, as a package.
#
# Every device that should follow this feed needs the same two files: the
# public half of the key under /etc/apk/keys, and a .list naming the tree for
# its release and architecture. Putting them in by hand is three commands that
# have to be got right per device and are then never touched again — which is
# how a fleet ends up pointing at a URL that moved two years ago.
#
# As a package they are maintained the way everything else is: install it once,
# untrusted, and from then on `apk upgrade` carries any change to the address
# or the key along with it. The one manual step is unavoidable and is the point
# where trust is established:
#
#     apk add --allow-untrusted ./ddimension-feed-*.apk
#
# After that the feed is signed and nothing needs --allow-untrusted again.
#
# Neither installed file is a conffile, and that is deliberate. A conffile is
# kept across upgrades, which is right for something the operator owns and
# wrong for this: an address that cannot be corrected by an update is exactly
# the problem the package exists to solve. Anyone who wants a different feed
# should add their own .list next to this one rather than edit this one — apk
# reads every file in repositories.d.
#
# The tree is chosen at build time, not on the device. It has to match the
# directory the site publishes under, and both halves of that come from the
# buildroot: the architecture is what this package was built for, and the
# release is derived from its version. A package from the openwrt-25.12 tree
# therefore points at openwrt-25.12 and cannot silently point somewhere else.
# After upgrading a device to a new OpenWrt release, install this package again
# from that release's tree — its .list still names the old one, which is
# visible rather than quiet, because apk update then says so.
#
# apk only. The usign key under keys/ is for opkg-based releases (<= 24.10),
# and those are no longer built; a package installing an /etc/opkg key on a
# system that has no opkg would be tidy-looking clutter.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/version.mk

PKG_NAME:=ddimension-feed
PKG_VERSION:=1
# 2: 1 never reached a device — it declared a dependency on apk-mbedtls and
# that broke the build before any package came out of it.
PKG_RELEASE:=2
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Andre Valentin <avalentin@marcant.net>

include $(INCLUDE_DIR)/package.mk

FEED_BASE:=https://ddimension.github.io/openwrt-repo

define Package/ddimension-feed
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=ddimension package feed: address and signing key
  URL:=https://github.com/ddimension/openwrt-repo
  # No DEPENDS. Depending on apk-mbedtls looked careful and was wrong twice
  # over: a package that installs into /etc/apk is installed *by* apk, so apk
  # is present by construction — OpenWrt packages do not declare the package
  # manager any more than they declare libc's existence. And declaring it drags
  # apk itself into the build, where the SDK cannot produce it:
  #
  #   ERROR: package/feeds/base/apk failed to build (build variant: mbedtls)
  #
  # which took the whole x86_64 leg of the feed build down.
endef

define Package/ddimension-feed/description
  Points apk at the ddimension package feed and installs the public key its
  indexes are signed with.

  Install it once with --allow-untrusted; after that the feed is trusted and
  every further change to its address or key arrives as an ordinary upgrade.

  The .list it writes names the tree for the release and architecture this
  package was built for. Neither file is a conffile: an address that an update
  cannot correct is the problem this package exists to avoid. To follow a
  second feed, add another file in /etc/apk/repositories.d rather than editing
  this one.
endef

Build/Configure:=

# The directory on the site, worked out from the buildroot rather than written
# down in two places that can drift apart.
#
# Getting this wrong is worse than failing to build: the package would install
# happily and point at a tree that does not exist, and the device would say
# nothing until somebody ran apk update by hand. So the two cases are handled
# explicitly and the result is printed, where CI keeps it.
#
# VERSION_NUMBER on a branch build is not what it looks like. Measured in a
# 25.12 buildroot: it is "25.12-SNAPSHOT", not "SNAPSHOT" — include/version.mk
# falls back to "<branch>-SNAPSHOT" when CONFIG_VERSION_NUMBER is unset. Naive
# splitting on the first dot turns that into "openwrt-25.12-SNAPSHOT". The
# suffix therefore comes off first, and what is left decides:
#
#     25.12.5          -> openwrt-25.12    a release
#     25.12-SNAPSHOT   -> openwrt-25.12    the 25.12 branch
#     SNAPSHOT         -> snapshot         master
#
# which are exactly the names the build workflow publishes under. Override with
# DDIMENSION_FEED_RELEASE for the day that stops being true.
define Build/Compile
	release='$(VERSION_NUMBER)'; \
	base="$$$${release%%-SNAPSHOT}"; \
	base="$$$${base%%SNAPSHOT}"; \
	case "$$$$base" in \
		[0-9]*.[0-9]*) dir="openwrt-$$$$(echo "$$$$base" | cut -d. -f1,2)" ;; \
		*)             dir="snapshot" ;; \
	esac; \
	dir="$$$${DDIMENSION_FEED_RELEASE:-$$$$dir}"; \
	echo "$(FEED_BASE)/$$$$dir/$(ARCH_PACKAGES)/packages.adb" \
		> $(PKG_BUILD_DIR)/ddimension.list; \
	echo "ddimension-feed: version '$$$$release' -> $$$$(cat $(PKG_BUILD_DIR)/ddimension.list)"
endef

define Package/ddimension-feed/install
	$(INSTALL_DIR) $(1)/etc/apk/keys
	$(INSTALL_DIR) $(1)/etc/apk/repositories.d
	$(INSTALL_DATA) ./files/ddimension.pem $(1)/etc/apk/keys/ddimension.pem
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/ddimension.list $(1)/etc/apk/repositories.d/ddimension.list
endef

# apk has the new index the moment the file lands, but nothing has fetched it
# yet, so the first `apk upgrade` after this would still not see the feed. One
# update here means the package is usable immediately rather than after a step
# nobody was told about.
define Package/ddimension-feed/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0
apk update >/dev/null 2>&1 || echo "ddimension-feed: apk update failed, run it by hand"
exit 0
endef

$(eval $(call BuildPackage,ddimension-feed))
