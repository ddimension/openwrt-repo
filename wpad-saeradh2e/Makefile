# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2006-2021 OpenWrt.org
#
# wpad-saeradh2e — the full/OpenSSL wpad from OpenWrt's hostapd package with
# our SAE-over-RADIUS patches (810-815) applied on top.
#
# This is a trimmed mirror of package/network/services/hostapd: everything
# that is not the wpad-full-openssl variant has been dropped, and the build
# variant is wired in directly instead of being derived from BUILD_VARIANT.
# The source pin and the 62 OpenWrt patches are unchanged from that package,
# so re-syncing means copying patches/, src/, files/ over and keeping the
# 81x-* patches.
#
# The package conflicts with every hostapd/wpa_supplicant provider of the base
# package and provides the same virtuals, so it is installed in place of wpad.
# hostapd-common comes from the base package and is not rebuilt here.

include $(TOPDIR)/rules.mk

PKG_NAME:=wpad-saeradh2e
PKG_RELEASE:=2

PKG_SOURCE_URL:=https://w1.fi/hostap.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2026-08-07
PKG_SOURCE_VERSION:=831364bf02710ad09c2f27d3efa92abeeb5634c0
PKG_MIRROR_HASH:=4a88e435103b4a2ce04fab6ac56bad1cac8f37281103f34317ee641ec22282ec

PKG_MAINTAINER:=Andre Valentin <avalentin@marcant.net>
PKG_LICENSE:=BSD-3-Clause
PKG_CPE_ID:=cpe:/a:w1.fi:hostapd

PKG_BUILD_PARALLEL:=1
PKG_ASLR_PIE_REGULAR:=1

PKG_CONFIG_DEPENDS:= \
	CONFIG_PACKAGE_wpad-saeradh2e \
	CONFIG_WPA_RFKILL_SUPPORT \
	CONFIG_DRIVER_11AC_SUPPORT \
	CONFIG_DRIVER_11AX_SUPPORT \
	CONFIG_DRIVER_11BE_SUPPORT \
	CONFIG_WPA_ENABLE_WEP

PKG_BUILD_FLAGS:=gc-sections lto

# Fixed variant: the full feature set, OpenSSL crypto. The basic/mini configs
# set CONFIG_NO_RADIUS=y, which would compile our patches out entirely, and
# the internal-TLS variant is built without CONFIG_SAE.
LOCAL_TYPE:=wpad
LOCAL_VARIANT:=full
SSL_VARIANT:=openssl
CONFIG_VARIANT:=full

include $(INCLUDE_DIR)/package.mk

TARGET_LDFLAGS_C:=$(TARGET_LDFLAGS)

STAMP_CONFIGURED:=$(STAMP_CONFIGURED)_$(CONFIG_WPA_MSG_MIN_PRIORITY)

ifneq ($(CONFIG_DRIVER_11AC_SUPPORT),)
  HOSTAPD_IEEE80211AC:=y
endif

ifneq ($(CONFIG_DRIVER_11AX_SUPPORT),)
  HOSTAPD_IEEE80211AX:=y
endif

ifneq ($(CONFIG_DRIVER_11BE_SUPPORT),)
  HOSTAPD_IEEE80211BE:=y
endif

# Both forced on, rather than left to the symbols above.
#
# Those symbols are selected by the wifi driver packages (ath.mk and friends
# carry +@DRIVER_11AX_SUPPORT in DEPENDS), and this package is built in an
# SDK against a package list that contains no kmod at all. It happens to work
# today - the binary from build 33211744602 carries he_bss_color and the
# ieee80211ax strings, checked on 2026-08-29 by unpacking the published apk on
# ap-av-attic - but that is the SDK's target defaults doing it, not anything
# this package asks for, and a fleet where every radio is 11ax should not
# depend on that.
#
# 11be follows because hostapd requires CONFIG_IEEE80211AX for it
# ("CONFIG_IEEE80211AX is mandatory for setting CONFIG_IEEE80211BE"), and no
# phy in the fleet reports EHT today: it is built for the hardware that comes,
# and costs nothing until a driver offers it.
HOSTAPD_IEEE80211AX:=y
HOSTAPD_IEEE80211BE:=y

CORE_DEPENDS = +ucode +libucode \
	+ucode-mod-fs +ucode-mod-nl80211 +ucode-mod-rtnl +ucode-mod-ubus +ucode-mod-uloop \
	+libubus +libblobmsg-json \
	+libudebug
OPENSSL_DEPENDS = +PACKAGE_$(1):libopenssl +PACKAGE_$(1):libopenssl-legacy
DRV_DEPENDS:=+libnl-tiny

DRIVER_MAKEOPTS= \
	CONFIG_ACS=y CONFIG_DRIVER_NL80211=y \
	CONFIG_IEEE80211AC=$(HOSTAPD_IEEE80211AC) \
	CONFIG_IEEE80211AX=$(HOSTAPD_IEEE80211AX) \
	CONFIG_IEEE80211BE=$(HOSTAPD_IEEE80211BE) \
	CONFIG_MBO=$(CONFIG_WPA_MBO_SUPPORT) \
	CONFIG_UCODE=y CONFIG_APUP=y \
	$(if $(HOSTAPD_IEEE80211BE),CONFIG_OCV=y)

DRIVER_MAKEOPTS += CONFIG_TLS=openssl CONFIG_SAE=y
TARGET_LDFLAGS += -lcrypto -lssl
DRIVER_MAKEOPTS += CONFIG_OWE=y CONFIG_SUITEB192=y CONFIG_AP=y CONFIG_MESH=y CONFIG_EAP_PWD=y CONFIG_DPP=y CONFIG_DPP2=y

ifdef CONFIG_WPA_RFKILL_SUPPORT
  DRIVER_MAKEOPTS += NEED_RFKILL=y
endif

ifdef CONFIG_WPA_ENABLE_WEP
  DRIVER_MAKEOPTS += CONFIG_WEP=y
endif

# --- what this build does that the stock full/openssl one does not ----------
#
# Kept here and not in files/hostapd-full.config on purpose: that file is a
# straight copy of upstream's, and the header of this Makefile says re-syncing
# means copying files/ over. A change made there would be reverted by the next
# sync without anyone noticing; a change made here survives it.

# TKIP is not merely unused in this fleet, it is absent: all ten bsses render
# wpa_pairwise=CCMP, measured 2026-08-29. Removing it takes out cryptography
# that is broken rather than old, and makes the binary smaller.
DRIVER_MAKEOPTS += CONFIG_NO_TKIP=y

# SAE Public Key. An access point proves its identity with a key pair, so a
# twin that knows the password cannot pass for it. The reason it is worth the
# space here: a station with a duplicated MAC has been knocking at ap-outdoor
# since 17.08.2026 and is handed another device's iPSK for its trouble, because
# with per-MAC keys the address is the whole identity. Building it in does not
# switch it on - that needs a key pair per network - but nothing can until the
# code is present.
DRIVER_MAKEOPTS += CONFIG_SAE_PK=y

# Fast Initial Link Setup, IEEE 802.11ai. Association in fewer frames for
# stations that can do it; the ones that cannot are unaffected. CONFIG_ERP is
# already on, which is what the shared-key variant needs.
DRIVER_MAKEOPTS += CONFIG_FILS=y

# Pre-Association Security Negotiation.
DRIVER_MAKEOPTS += CONFIG_PASN=y

# IEEE P802.11bi: encrypted association frames, and 802.1X carried in
# authentication frames. IEEE8021X_AUTH needs ENC_ASSOC, so they go together.
#
# hostapd's own defconfig says of these: "These features are experimental and
# still changing; do not enable for production use." Enabled deliberately
# anyway, on 2026-08-29. Nothing offers them unless a bss is configured for
# them, so the cost of carrying the code is size and attack surface, not
# behaviour - but the warning is upstream's, not a guess, and it is the first
# thing to undo if this build ever misbehaves in a way nothing else explains.
DRIVER_MAKEOPTS += CONFIG_ENC_ASSOC=y CONFIG_IEEE8021X_AUTH=y

# hostapd's own RADIUS server, out. /etc/config/radius carries disabled '1' on
# every access point, no bss configures radius_server_clients, and udp/1812 is
# held by the agent's own Lua server - measured on ap-av-grwz 2026-08-29. The
# files that drove it are dropped from the install below, because an init
# script for a server that is no longer in the binary is worse than an unused
# one. This is the built-in server only; the RADIUS *client*, which everything
# on this fleet depends on and which CONFIG_NO_RADIUS would remove, stays.
DRIVER_MAKEOPTS += CONFIG_RADIUS_SERVER=

# Every hostapd/wpa_supplicant provider of the base package. Installing this
# one has to replace whichever of them is on the device.
BASE_PROVIDERS:= \
	hostapd hostapd-basic hostapd-basic-openssl hostapd-basic-wolfssl \
	hostapd-basic-mbedtls hostapd-mini hostapd-openssl hostapd-wolfssl \
	hostapd-mbedtls \
	wpad wpad-mesh-openssl wpad-mesh-wolfssl wpad-mesh-mbedtls wpad-basic \
	wpad-basic-openssl wpad-basic-wolfssl wpad-basic-mbedtls wpad-mini \
	wpad-openssl wpad-wolfssl wpad-mbedtls \
	wpa-supplicant wpa-supplicant-mesh-openssl wpa-supplicant-mesh-wolfssl \
	wpa-supplicant-mesh-mbedtls wpa-supplicant-basic wpa-supplicant-mini \
	wpa-supplicant-p2p wpa-supplicant-openssl wpa-supplicant-wolfssl \
	wpa-supplicant-mbedtls

define Package/wpad-saeradh2e
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WirelessAPD
  TITLE:=IEEE 802.1x Auth/Supplicant (OpenSSL full, SAE over RADIUS)
  DEPENDS:=$(DRV_DEPENDS) +hostapd-common $(CORE_DEPENDS) $(OPENSSL_DEPENDS)
  USERID:=network=101:network=101
  URL:=https://w1.fi/
  PROVIDES:=hostapd wpa-supplicant
  CONFLICTS:=$(BASE_PROVIDERS)
  VARIANT:=wpad-full-openssl
endef

define Package/wpad-saeradh2e/description
 The full featured IEEE 802.1x/WPA/EAP/RADIUS Authenticator and Supplicant
 built against OpenSSL, with additional patches that make SAE usable with a
 password from a RADIUS server:

 - hash-to-element works with a RADIUS supplied password, so WPA3 with
   per-station keys is no longer restricted to the hunting and pecking loop
 - an SAE Password Identifier can be looked up from the RADIUS server
   (sae_password_radius=1)
 - the credential a station used is reported as identity= and
   sae_password_id= in the STA info and in the AP-STA-CONNECTED event
endef

define Build/Configure
	$(Build/Configure/rebuild)
	$(CP) ./files/hostapd-full.config $(PKG_BUILD_DIR)/hostapd/.config
	$(CP) ./files/wpa_supplicant-full.config $(PKG_BUILD_DIR)/wpa_supplicant/.config
endef

ifneq ($(wildcard $(PKG_BUILD_DIR)/.config_*),$(subst .configured_,.config_,$(STAMP_CONFIGURED)))
  define Build/Configure/rebuild
	$(FIND) $(PKG_BUILD_DIR) -name \*.o -or -name \*.a | $(XARGS) rm -f
	rm -f $(PKG_BUILD_DIR)/hostapd/hostapd
	rm -f $(PKG_BUILD_DIR)/wpa_supplicant/wpa_supplicant
	rm -f $(PKG_BUILD_DIR)/.config_*
	touch $(subst .configured_,.config_,$(STAMP_CONFIGURED))
  endef
endif

TARGET_CPPFLAGS := \
	-I$(STAGING_DIR)/usr/include/libnl-tiny \
	-I$(PKG_BUILD_DIR)/src/crypto \
	$(TARGET_CPPFLAGS) \
	-DCONFIG_LIBNL20 \
	-D_GNU_SOURCE \
	$(if $(CONFIG_WPA_MSG_MIN_PRIORITY),-DCONFIG_MSG_MIN_PRIORITY=$(CONFIG_WPA_MSG_MIN_PRIORITY))

TARGET_LDFLAGS += -lubox -lubus -lblobmsg_json -lucode -lm -lnl-tiny -ludebug

define Build/RunMake
	CFLAGS="$(TARGET_CPPFLAGS) $(TARGET_CFLAGS)" \
	$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR)/$(1) \
		$(TARGET_CONFIGURE_OPTS) \
		$(DRIVER_MAKEOPTS) \
		LIBS="$(TARGET_LDFLAGS)" \
		LIBS_c="$(TARGET_LDFLAGS_C)" \
		AR="$(TARGET_CROSS)gcc-ar" \
		BCHECK= \
		$(if $(findstring s,$(OPENWRT_VERBOSE)),V=1) \
		$(2)
endef

define Build/Compile
	echo ` \
		$(call Build/RunMake,hostapd,-s MULTICALL=1 dump_cflags); \
		$(call Build/RunMake,wpa_supplicant,-s MULTICALL=1 dump_cflags) | \
		sed -e 's,-n ,,g' -e 's^$(TARGET_CFLAGS)^^' \
	` > $(PKG_BUILD_DIR)/.cflags
	sed -i 's/"/\\"/g' $(PKG_BUILD_DIR)/.cflags
	+$(call Build/RunMake,hostapd, \
		CFLAGS="$$$$(cat $(PKG_BUILD_DIR)/.cflags)" \
		MULTICALL=1 \
		hostapd_cli hostapd_multi.a \
	)
	+$(call Build/RunMake,wpa_supplicant, \
		CFLAGS="$$$$(cat $(PKG_BUILD_DIR)/.cflags)" \
		MULTICALL=1 \
		wpa_cli wpa_supplicant_multi.a \
	)
	+export MAKEFLAGS="$(MAKE_JOBSERVER)"; $(TARGET_CC) -o $(PKG_BUILD_DIR)/wpad \
		$(TARGET_CFLAGS) \
		./files/multicall.c \
		$(PKG_BUILD_DIR)/hostapd/hostapd_multi.a \
		$(PKG_BUILD_DIR)/wpa_supplicant/wpa_supplicant_multi.a \
		$(TARGET_LDFLAGS)
endef

define Package/wpad-saeradh2e/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/share/hostap
	$(INSTALL_DATA) ./files/hostapd.uc $(1)/usr/share/hostap/
	$(INSTALL_DATA) ./files/wpa_supplicant.uc $(1)/usr/share/hostap/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/wpad $(1)/usr/sbin/
	$(LN) wpad $(1)/usr/sbin/hostapd
	$(LN) wpad $(1)/usr/sbin/wpa_supplicant
endef

$(eval $(call BuildPackage,wpad-saeradh2e))
