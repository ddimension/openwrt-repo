#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qfirehose
PKG_VERSION:=1.4.21
PKG_RELEASE:=2
# License: Quectel NOTICE in the source tree — binary redistribution to
# Quectel customers permitted; source disclosure restricted by Quectel.
PKG_LICENSE:=Quectel-Proprietary
PKG_LICENSE_FILES:=NOTICE
PKG_MAINTAINER:=André Valentin <a.valentin@ddimension.net>

# Quectel ships QFirehose only as a zip; the release is not on any public
# git remote, so the archive lives in files/ and is unpacked in Build/Prepare
# instead of being fetched.
PKG_SOURCE_FILE:=$(PKG_NAME)-$(PKG_VERSION).zip
PKG_SOURCE_TOPDIR:=QFirehose_Linux_and_Android_V$(PKG_VERSION)

# Link-time optimisation and dead-code stripping; package.mk turns these into
# the matching TARGET_CFLAGS/TARGET_LDFLAGS.
PKG_BUILD_FLAGS:=gc-sections lto

include $(INCLUDE_DIR)/package.mk

define Package/qfirehose
  SECTION:=net
  CATEGORY:=Network
  TITLE:=QFirehose firmware update tool for Quectel devices
  DEPENDS:=+libpthread
endef

define Package/qfirehose/description
  QFirehose firmware update tool for Quectel devices (sahara/firehose protocol)
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR) $(PKG_BUILD_DIR).unpack
	mkdir -p $(PKG_BUILD_DIR).unpack
	unzip -q $(CURDIR)/files/$(PKG_SOURCE_FILE) -d $(PKG_BUILD_DIR).unpack
	mv $(PKG_BUILD_DIR).unpack/$(PKG_SOURCE_TOPDIR) $(PKG_BUILD_DIR)
	rm -rf $(PKG_BUILD_DIR).unpack
	$(Build/Patch)
endef

# 100-makefile-toolchain.patch moves -lpthread/-ldl into LIBS, so passing
# LDFLAGS= here no longer drops them. The leading + hands the jobserver down
# to GCC's LTO stage.
define Build/Compile
	+$(MAKE) -C $(PKG_BUILD_DIR) linux \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) $(TARGET_CPPFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/qfirehose/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/out/QFirehose $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,qfirehose))
