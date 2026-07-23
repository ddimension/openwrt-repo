#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qfirehose
PKG_VERSION:=2.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/nippynetworks/qfirehose.git
PKG_SOURCE_VERSION:=f77d6729dcf72295e2c024782946cf8ac8a2d8c1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MIRROR_HASH:=1260897adee46bc320150503ef729294c3eec1d976b4e1230cb44961a38c76ba

PKG_BUILD_DIR:=$(BUILD_DIR)/qfirehose-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/qfirehose
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+librt +libstdcpp
  TITLE:=qfirehose firmware update tool for quectel devices
endef

define Package/qfirehose/description
  qfirehose firmware update tool for quectel devices
endef

define Package/qfirehose/conffiles
endef


TARGET_CFLAGS += -ffunction-sections $(FPIC)
TARGET_CFLAGS += -flto
TARGET_LDFLAGS += -flto=jobserver -fuse-linker-plugin
TARGET_LDFLAGS += -Wno-error=format-truncation

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) CROSS_COMPILE=$(TARGET_CROSS) CFLAGS="$(TARGET_CFLAGS)" LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/qfirehose/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/QFirehose $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,qfirehose))
