#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=homesync
PKG_VERSION:=7
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/homesync
  SECTION:=admin
  CATEGORY:=Multimedia
  TITLE:=homesync
  DEPENDS:=+snapcast-client +alsa-utils +kmod-usb-audio +kmod-usb-hid
  MAINTAINER:=Andre Valentin <avalentin@marcant.net>
  PKGARCH:=all
endef

define Package/homesync/description
Sets up synchronized speaker,
endef

define Build/Compile
endef

define Build/Configure
endef

define Package/homesync/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/hotplug.d/usb
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/etc/init.d/homesync $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/etc/hotplug.d/usb/30-homesync-usb-audio $(1)/etc/hotplug.d/usb/
	$(INSTALL_CONF) ./files/etc/config/homesync $(1)/etc/config/
	$(INSTALL_BIN) ./files/usr/bin/homesync $(1)/usr/bin/
endef

$(eval $(call BuildPackage,homesync))

