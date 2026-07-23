#
# Copyright (C) 2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luacurl
PKG_VERSION:=0.3.11
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Lua-cURL/Lua-cURLv3.git
PKG_SOURCE_VERSION:=c38f3d4c298a1ce941158e0b8bc9ea5ca40fe655
PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/luacurl
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Lua-cURL
  URL:=http://msva.github.io/lua-curl/
  DEPENDS:=+liblua +libcurl
endef

define Package/luacurl/description
	Lua-cURL is aiming for a full-fledged libcurl binding (easy/multi/share
	interface) to the functionality of Lua
endef

MAKE_FLAGS += \
	LUA="$(STAGING_DIR)/usr" \
	OFLAGS="$(TARGET_CFLAGS)" \


define Package/luacurl/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lcurl.so $(1)/usr/lib/lua/
endef

$(eval $(call BuildPackage,luacurl))
