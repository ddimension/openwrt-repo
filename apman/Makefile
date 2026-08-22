#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=apman
PKG_VERSION:=60
PKG_RELEASE:=2
PKG_LICENSE:=GPL-2.0-only

# The agent has its own repository; this package only installs it. A pinned
# commit, not a branch, so a rebuild of an old release produces the old agent —
# and PKG_MIRROR_HASH is what makes that a fact rather than a hope: it is the
# sha256 of the tarball OpenWrt packs itself out of the checkout, not of
# anything GitHub serves. Both values come from contrib/release.sh in the agent
# repository, which also bumps PKG_VERSION — the tarball is named after it, so
# leaving it alone would let two different commits share one download cache
# entry.
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ddimension/apman-agent.git
PKG_SOURCE_VERSION:=efa2daa328c1179543e99d3ad45cd546e595abfd
PKG_MIRROR_HASH:=1c436bf868b1eed47157a0a3ffbd3577271bb879a6335cbf6b64e7bd6c1b7f54

include $(INCLUDE_DIR)/package.mk

define Package/apman
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=AP Management
  MAINTAINER:=Andre Valentin <avalentin@marcant.net>
  DEPENDS:= +lua +libubox-lua +libubus-lua-async +luasocket +lua-cjson +lua-mosquitto +collectd-mod-lua +lua-md5
  PKGARCH:=all
endef

define Package/apman/description
AP Management and statistics via collectd
endef

define Build/Compile
endef

define Build/Configure
endef


# Carried over by sysupgrade. The key store is the only thing on the access
# point that the controller cannot simply reproduce on demand — it is what
# lets the agent answer stations in the minutes between a reboot and the next
# distribution — so it has to survive a firmware upgrade like a config file.
define Package/apman/conffiles
/etc/config/apman
endef

define Package/apman/install
	$(INSTALL_DIR) $(1)/etc/apman
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/init.d/apman-status $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/etc/config/apman $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/collectd/conf.d
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/etc/collectd/conf.d/lua-apman.conf $(1)/etc/collectd/conf.d
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/bin/apman-status $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/lib/lua/apman.lua $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/lib/lua/apman-collectd.lua $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/lib/lua/apman-radius.lua $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/lib/lua/apman-ctrl.lua $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/lib/lua/apman-parse.lua $(1)/usr/lib/lua
	$(INSTALL_DIR) $(1)/lib/upgrade/keep.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/lib/upgrade/keep.d/apman $(1)/lib/upgrade/keep.d/
	$(INSTALL_DIR) $(1)/usr/share/collectd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/share/collectd/types.apman.db $(1)/usr/share/collectd/types.apman.db
endef

$(eval $(call BuildPackage,apman))
