#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qlog
PKG_VERSION:=1.5.8
PKG_RELEASE:=1

#PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

PKG_BUILD_DIR:=$(BUILD_DIR)/QLog

define prepare_source_directory
	rm -rf $(PKG_BUILD_DIR)
	unzip files/Quectel_QLog_Linux\&Android_V1.5.8.zip -d $(BUILD_DIR)
endef
Hooks/Prepare/Pre += prepare_source_directory


include $(INCLUDE_DIR)/package.mk

define Package/qlog
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+librt +libstdcpp
  TITLE:=qlog firmware update tool for quectel devices
endef

define Package/qlog/description
  qlog firmware update tool for quectel devices
endef

define Package/qlog/conffiles
endef


TARGET_CFLAGS += -ffunction-sections $(FPIC)
TARGET_CFLAGS += -flto
TARGET_LDFLAGS += -flto=jobserver -fuse-linker-plugin

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) CROSS_COMPILE=$(TARGET_CROSS) CFLAGS="$(TARGET_CFLAGS)" LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/qlog/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/QLog $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,qlog))
