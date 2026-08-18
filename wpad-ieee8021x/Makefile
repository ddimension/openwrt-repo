#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=wpad-ieee8021x
PKG_VERSION:=1
PKG_RELEASE:=2

include $(INCLUDE_DIR)/package.mk

define Package/wpad-ieee8021x
  SECTION:=admin
  CATEGORY:=device
  TITLE:=wpad-ieee8021x
  MAINTAINER:=Andre Valentin <avalentin@marcant.net>
  DEPENDS:=wpa-supplicant
  PKGARCH:=all
endef

define Package/wpad-ieee8021x/description
Extends system with IEE802.1X wire authentication.
endef

define Package/strongswan/conffiles
/etc/wpad/
endef

define Build/Compile
endef

define Build/Configure
endef

define Package/wpad-ieee8021x/install
	$(INSTALL_DIR) $(1)/etc/wpad
	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) ./files/lib/netifd/proto/ieee8021x.sh $(1)/lib/netifd/proto/ieee8021x.sh
endef

$(eval $(call BuildPackage,wpad-ieee8021x))

