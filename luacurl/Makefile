#
# Copyright (C) 2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luacurl
PKG_VERSION:=0.3.13
PKG_RELEASE:=1
PKG_MAINTAINER:=A. Valentin <avalentin@marcant.net>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Lua-cURL/Lua-cURLv3.git
PKG_SOURCE_VERSION:=833e87c830bed05fe3910a33f573c202a48ba6d4
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
# The source version belongs in the tarball name: without it a version bump
# that keeps PKG_VERSION would reuse the stale tarball sitting in dl/.
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MIRROR_HASH:=b97dae6d76ba09340ec95ecd8aabe6fff8c417ee52347bc3359a8b0a3817ec49

PKG_BUILD_FLAGS:=gc-sections lto

include $(INCLUDE_DIR)/package.mk

define Package/luacurl
  SUBMENU:=Lua
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Lua-cURL
  URL:=https://github.com/Lua-cURL/Lua-cURLv3
  DEPENDS:=+liblua +libcurl
endef

define Package/luacurl/description
	Lua-cURL is aiming for a full-fledged libcurl binding (easy/multi/share
	interface) to the functionality of Lua
endef

# COMMONFLAGS carries the upstream defaults `-O2 -g -pipe -fPIC $(OS_FLAGS)`,
# which would fight the target's own -Os and bloat the objects with debug
# info. Override it with just what the shared module actually needs; the
# target flags themselves arrive via the CFLAGS that MAKE_VARS exports, which
# the upstream Makefile appends to its own CF.
MAKE_FLAGS += \
	COMMONFLAGS="-fPIC -shared"

define Package/luacurl/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lcurl.so $(1)/usr/lib/lua/
	# The documented API is the `cURL` Lua layer on top of the C module;
	# without these files `require "cURL"` fails.
	$(INSTALL_DIR) $(1)/usr/lib/lua/cURL/impl
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/lua/cURL.lua $(1)/usr/lib/lua/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/lua/cURL/safe.lua $(1)/usr/lib/lua/cURL/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/lua/cURL/utils.lua $(1)/usr/lib/lua/cURL/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/lua/cURL/impl/cURL.lua $(1)/usr/lib/lua/cURL/impl/
endef

$(eval $(call BuildPackage,luacurl))
