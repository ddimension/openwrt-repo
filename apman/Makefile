#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=apman
PKG_VERSION:=56
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/apman
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=AP Management
  MAINTAINER:=Andre Valentin <avalentin@marcant.net>
  DEPENDS:= +lua +libubox-lua +libubus-lua +luasocket +lua-cjson +lua-mosquitto +collectd-mod-lua
  PKGARCH:=all
endef

define Package/apman/description
AP Management and statistics via collectd
endef

define Build/Compile
endef

define Build/Configure
endef


define Package/apman/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/apman-status $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/apman $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/collectd/conf.d
	$(INSTALL_CONF) ./files/etc/collectd/conf.d/lua-apman.conf $(1)/etc/collectd/conf.d
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/apman-status $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_BIN) ./files/usr/lib/lua/apman.lua $(1)/usr/lib/lua
	$(INSTALL_BIN) ./files/usr/lib/lua/apman-collectd.lua $(1)/usr/lib/lua
	$(INSTALL_DIR) $(1)/usr/share/collectd
	$(INSTALL_BIN) ./files/usr/share/collectd/types.apman.db $(1)/usr/share/collectd/types.apman.db
endef

$(eval $(call BuildPackage,apman))
