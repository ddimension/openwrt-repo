#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=wpad-ieee8021x
PKG_VERSION:=1
PKG_RELEASE:=3
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Andre Valentin <avalentin@marcant.net>

include $(INCLUDE_DIR)/package.mk

# wpa-supplicant is a virtual package (wpad* and the wpa-supplicant-*
# variants provide it), so this is an unprefixed dependency: the user picks
# a provider, and this package becomes selectable once one is in the build.
define Package/wpad-ieee8021x
  SECTION:=net
  CATEGORY:=Network
  TITLE:=IEEE 802.1X wired authentication protocol for netifd
  DEPENDS:=wpa-supplicant
  PKGARCH:=all
endef

define Package/wpad-ieee8021x/description
  Adds an `ieee8021x` netifd protocol that authenticates a wired interface
  through wpa_supplicant's ubus interface. Put the wpa_supplicant config
  file somewhere such as /etc/wpad and point the interface's `wpad_config`
  option at it.
endef

Build/Compile:=
Build/Configure:=

define Package/wpad-ieee8021x/install
	$(INSTALL_DIR) $(1)/etc/wpad
	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) ./files/lib/netifd/proto/ieee8021x.sh $(1)/lib/netifd/proto/ieee8021x.sh
endef

$(eval $(call BuildPackage,wpad-ieee8021x))
