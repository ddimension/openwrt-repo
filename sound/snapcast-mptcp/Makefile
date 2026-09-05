# SPDX-License-Identifier: GPL-2.0-or-later
#
# Mirror of sound/snapcast from the openwrt/packages feed, built from the
# ddimension/snapcast fork (feature/mptcp branch) instead of upstream.
# The config symbols and package names are suffixed with -mptcp so that the
# package can coexist with the stock snapcast in the same tree.

include $(TOPDIR)/rules.mk

PKG_NAME:=snapcast-mptcp
PKG_VERSION:=0.35.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ddimension/snapcast.git
PKG_SOURCE_VERSION:=becef987673f3ad0ab10d660b5194a325f579075
PKG_MIRROR_HASH:=1e2fe34676d5f2059ccfbbc4771866766529e2d3241435193da3621787586eca

PKG_MAINTAINER:=Szabolcs Hubai <szab.hu@gmail.com>, David Andreoletti <david@andreoletti.net>
PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:badaix:snapcast

# Optional features are individually selectable (see Package/snapserver-mptcp/config).
# Listing the symbols here reconfigures and rebuilds the package whenever any of
# them is toggled.
PKG_CONFIG_DEPENDS:= \
	CONFIG_SNAPCAST_MPTCP_ALSA \
	CONFIG_SNAPCAST_MPTCP_AVAHI \
	CONFIG_SNAPCAST_MPTCP_EXPAT \
	CONFIG_SNAPCAST_MPTCP_FLAC \
	CONFIG_SNAPCAST_MPTCP_OPUS \
	CONFIG_SNAPCAST_MPTCP_SOXR \
	CONFIG_SNAPCAST_MPTCP_SSL \
	CONFIG_SNAPCAST_MPTCP_VORBIS

# snapserver and snapclient are produced by a single source build, so every
# enabled feature library must be staged whenever the source is built,
# regardless of which of the two binary packages is selected. These are pure
# build-time prerequisites; the precise per-binary runtime dependencies (what
# actually lands on the target) are declared in each Package/* DEPENDS below.
PKG_BUILD_DEPENDS:= \
	$(if $(CONFIG_SNAPCAST_MPTCP_ALSA),alsa-lib) \
	$(if $(CONFIG_SNAPCAST_MPTCP_AVAHI),libavahi-client) \
	$(if $(CONFIG_SNAPCAST_MPTCP_EXPAT),libexpat) \
	$(if $(CONFIG_SNAPCAST_MPTCP_FLAC),libflac) \
	$(if $(CONFIG_SNAPCAST_MPTCP_OPUS),libopus) \
	$(if $(CONFIG_SNAPCAST_MPTCP_SOXR),libsoxr) \
	$(if $(CONFIG_SNAPCAST_MPTCP_SSL),libopenssl) \
	$(if $(CONFIG_SNAPCAST_MPTCP_VORBIS),libvorbis libvorbisidec) \
	boost

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

# Every upstream build switch is pinned explicitly for reproducible builds; the
# optional ones follow their config symbol. Client-only desktop backends other
# than ALSA are unavailable on OpenWrt and stay off.
CMAKE_OPTIONS += \
	-DBUILD_TESTS=OFF \
	-DBUILD_WITH_ALSA=$(if $(CONFIG_SNAPCAST_MPTCP_ALSA),ON,OFF) \
	-DBUILD_WITH_AVAHI=$(if $(CONFIG_SNAPCAST_MPTCP_AVAHI),ON,OFF) \
	-DBUILD_WITH_EXPAT=$(if $(CONFIG_SNAPCAST_MPTCP_EXPAT),ON,OFF) \
	-DBUILD_WITH_FLAC=$(if $(CONFIG_SNAPCAST_MPTCP_FLAC),ON,OFF) \
	-DBUILD_WITH_JACK=OFF \
	-DBUILD_WITH_OPUS=$(if $(CONFIG_SNAPCAST_MPTCP_OPUS),ON,OFF) \
	-DBUILD_WITH_PIPEWIRE=OFF \
	-DBUILD_WITH_PULSE=OFF \
	-DBUILD_WITH_SDL2=OFF \
	-DBUILD_WITH_SOXR=$(if $(CONFIG_SNAPCAST_MPTCP_SOXR),ON,OFF) \
	-DBUILD_WITH_SSL=$(if $(CONFIG_SNAPCAST_MPTCP_SSL),ON,OFF) \
	-DBUILD_WITH_TREMOR=$(if $(CONFIG_SNAPCAST_MPTCP_VORBIS),ON,OFF) \
	-DBUILD_WITH_VORBIS=$(if $(CONFIG_SNAPCAST_MPTCP_VORBIS),ON,OFF) \
	-DWERROR=OFF

define Package/snapcast-mptcp/Default
  SECTION:=sound
  CATEGORY:=Sound
  TITLE:=Synchronous multiroom audio player (MPTCP)
  URL:=https://github.com/ddimension/snapcast
  # Dependencies common to both binaries. Feature libraries that only one of the
  # two links are added in the respective package below, so each package pulls
  # only what its binary actually needs at runtime.
  DEPENDS:= \
	+SNAPCAST_MPTCP_ALSA:alsa-lib \
	+SNAPCAST_MPTCP_AVAHI:libavahi-client \
	+SNAPCAST_MPTCP_FLAC:libflac \
	+SNAPCAST_MPTCP_OPUS:libopus \
	+SNAPCAST_MPTCP_SSL:libopenssl \
	+libatomic \
	+libogg \
	+libstdcpp
endef

define Package/snapcast-mptcp/Default/description
  Synchronous audio player - Snapcast with Multipath TCP support

  Snapcast is a multi-room client-server audio player,
  where all clients are time synchronized with the server
  to play perfectly synced audio.
  This variant is built from the ddimension/snapcast MPTCP fork:
  snapserver and snapclient create their stream sockets with
  IPPROTO_MPTCP when the kernel supports it, so audio survives
  the loss of a network path (e.g. WiFi handover) without a
  reconnect.
endef

# The optional-feature menu is shared by both binaries (single source build), so
# it is declared once. The symbols are free-standing (no "depends on
# PACKAGE_*"): the packages reference them in DEPENDS, and a back-dependency
# here would form a Kconfig recursion.
define Package/snapserver-mptcp/config
	menu "Snapcast MPTCP feature selection"

		config SNAPCAST_MPTCP_ALSA
			bool "ALSA support (server capture source + client playback)"
			default y
			help
				Adds a dependency on alsa-lib.

		config SNAPCAST_MPTCP_AVAHI
			bool "Avahi / zeroconf support"
			default n
			help
				Adds a dependency on libavahi-client.

		config SNAPCAST_MPTCP_EXPAT
			bool "EXPAT / XML support (server)"
			default y
			help
				Adds a dependency on libexpat.

		config SNAPCAST_MPTCP_FLAC
			bool "FLAC codec support"
			default y
			help
				Adds a dependency on libflac.

		config SNAPCAST_MPTCP_OPUS
			bool "Opus codec support"
			default y
			help
				Adds a dependency on libopus.

		config SNAPCAST_MPTCP_SOXR
			bool "SOXR resampling support (server + client)"
			default y
			help
				High-quality SoX resampling, compiled into
				both binaries (build-wide -DBUILD_WITH_SOXR).
				Adds a dependency on libsoxr to each.

		config SNAPCAST_MPTCP_SSL
			bool "SSL / TLS support"
			default n
			help
				Adds a dependency on libopenssl.

		config SNAPCAST_MPTCP_VORBIS
			bool "Ogg Vorbis support (server encoder + client Tremor decoder)"
			default y
			help
				Adds dependencies on libvorbis (server) and
				libvorbisidec (client).
	endmenu
endef

define Package/snapserver-mptcp
  $(call Package/snapcast-mptcp/Default)
  TITLE+= (server)
  DEPENDS+= \
	+SNAPCAST_MPTCP_EXPAT:libexpat \
	+SNAPCAST_MPTCP_SOXR:libsoxr \
	+SNAPCAST_MPTCP_VORBIS:libvorbis
  CONFLICTS:=snapserver
endef

define Package/snapclient-mptcp
  $(call Package/snapcast-mptcp/Default)
  TITLE+= (client)
  DEPENDS+= \
	+SNAPCAST_MPTCP_SOXR:libsoxr \
	+SNAPCAST_MPTCP_VORBIS:libvorbisidec
  CONFLICTS:=snapclient
endef

define Package/snapserver-mptcp/description
  $(call Package/snapcast-mptcp/Default/description)
  This package contains the Snapcast server (MPTCP variant).
endef

define Package/snapclient-mptcp/description
  $(call Package/snapcast-mptcp/Default/description)
  This package contains the Snapcast client (MPTCP variant).
endef

define Package/snapserver-mptcp/conffiles
/etc/config/snapserver
/etc/snapserver.conf
endef

define Package/snapclient-mptcp/conffiles
/etc/config/snapclient
endef

define Package/snapserver-mptcp/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/snapserver $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/snapserver.init $(1)/etc/init.d/snapserver
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/server/etc/snapserver.conf $(1)/etc/snapserver.conf
	$(SED) 's/.*doc_root *=/#doc_root =/' $(1)/etc/snapserver.conf
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/snapserver.conf $(1)/etc/config/snapserver
endef

define Package/snapclient-mptcp/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/snapclient $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/snapclient.init $(1)/etc/init.d/snapclient
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/snapclient.conf $(1)/etc/config/snapclient
endef

$(eval $(call BuildPackage,snapserver-mptcp))
$(eval $(call BuildPackage,snapclient-mptcp))
