#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qflash
PKG_VERSION:=2.0
PKG_RELEASE:=2
# License: Quectel-proprietary legacy tool, archived upstream at V2.0.
PKG_LICENSE:=Quectel-Proprietary
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=André Valentin <a.valentin@ddimension.net>

# QFlash 2.0 is an archived Quectel drop with no public git remote; the
# tarball lives in files/ and is unpacked in Build/Prepare instead of fetched.
PKG_SOURCE_FILE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

# Link-time optimisation and dead-code stripping; package.mk turns these into
# the matching TARGET_CFLAGS/TARGET_CXXFLAGS/TARGET_LDFLAGS.
PKG_BUILD_FLAGS:=gc-sections lto

include $(INCLUDE_DIR)/package.mk

define Package/qflash
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libstdcpp +libpthread +librt
  TITLE:=QFlash legacy firmware update tool for Quectel devices
endef

define Package/qflash/description
  QFlash 2.0, the legacy Quectel firmware update tool
  (fastboot/sahara/streaming/firehose)
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) -xzf $(CURDIR)/files/$(PKG_SOURCE_FILE) -C $(PKG_BUILD_DIR) \
		--strip-components=1
	$(Build/Patch)
endef

# The C sources share globals (endian_flag) via tentative definitions, which
# GCC >= 10 rejects under its -fno-common default.
TARGET_CFLAGS += -fcommon

# The sources predate C++17 and carry their own `typedef unsigned char byte`
# next to a `using namespace std`, which is ambiguous against std::byte under
# GCC 14's default of gnu++17.
TARGET_CXXFLAGS += -std=gnu++14

# 100-makefile-toolchain.patch teaches the upstream Makefile to honour
# CC/CXX/CFLAGS/CXXFLAGS/LDFLAGS; without it the target flags below are
# silently dropped and only CROSS_COMPILE has any effect. The leading + hands
# the jobserver down to GCC's LTO stage.
define Build/Compile
	+$(MAKE) -C $(PKG_BUILD_DIR) all \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		CC="$(TARGET_CC)" \
		CXX="$(TARGET_CXX)" \
		CFLAGS="$(TARGET_CFLAGS) $(TARGET_CPPFLAGS)" \
		CXXFLAGS="$(TARGET_CXXFLAGS) $(TARGET_CPPFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/qflash/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/QFlash $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,qflash))
