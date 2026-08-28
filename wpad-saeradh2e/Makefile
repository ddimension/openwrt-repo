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
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://w1.fi/hostap.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2026-08-07
PKG_SOURCE_VERSION:=831364bf02710ad09c2f27d3efa92abeeb5634c0
PKG_MIRROR_HASH:=d1b9ca0e6aaaba928fc5d5b02c0084083e745a38ae1214d0e2dc5d1ea6d50393

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

define Package/wpad-saeradh2e/conffiles
/etc/config/radius
/etc/radius
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
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/etc/config $(1)/etc/radius
	ln -sf hostapd $(1)/usr/sbin/hostapd-radius
	$(INSTALL_BIN) ./files/radius.init $(1)/etc/init.d/radius
	$(INSTALL_DATA) ./files/radius.config $(1)/etc/config/radius
	$(INSTALL_DATA) ./files/radius.clients $(1)/etc/radius/clients
	$(INSTALL_DATA) ./files/radius.users $(1)/etc/radius/users
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/wpad $(1)/usr/sbin/
	$(LN) wpad $(1)/usr/sbin/hostapd
	$(LN) wpad $(1)/usr/sbin/wpa_supplicant
endef

$(eval $(call BuildPackage,wpad-saeradh2e))
