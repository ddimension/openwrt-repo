#
# Copyright (C) 2006-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qlog
PKG_VERSION:=1.5.8
PKG_RELEASE:=2
# License: NOTICE in the bundled zip — "public domain software for
# customers of Quectel", free to modify/redistribute for Quectel
# customers; all rights reserved towards non-customers.
PKG_LICENSE:=Quectel-Customer-Use
PKG_LICENSE_FILES:=NOTICE
PKG_MAINTAINER:=André Valentin <a.valentin@ddimension.net>

#PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

PKG_BUILD_DIR:=$(BUILD_DIR)/QLog

# The zip's Tn.*.cfg filter profiles carry a Chinese description as part of
# the filename itself. Renaming them here via glob (not by retyping the CJK
# bytes into this Makefile) keeps the match independent of this file's own
# encoding and of whatever locale unzip runs under in the build container.
define prepare_source_directory
	rm -rf $(PKG_BUILD_DIR)
	unzip files/Quectel_QLog_Linux\&Android_V1.5.8.zip -d $(BUILD_DIR)
	mv $(PKG_BUILD_DIR)/conf/T1.LinuxData-OTA-DataService-*.cfg $(PKG_BUILD_DIR)/conf/T1-data-ota-dataservice.cfg
	mv $(PKG_BUILD_DIR)/conf/T2.RegServ-CotextAct-*.cfg $(PKG_BUILD_DIR)/conf/T2-registration-context-activation.cfg
	mv $(PKG_BUILD_DIR)/conf/T3.SimpleData-*.cfg $(PKG_BUILD_DIR)/conf/T3-simple-data.cfg
	mv $(PKG_BUILD_DIR)/conf/T4.Throughput-*.cfg $(PKG_BUILD_DIR)/conf/T4-throughput.cfg
	mv $(PKG_BUILD_DIR)/conf/T5.COMMON-*.cfg $(PKG_BUILD_DIR)/conf/T5-common.cfg
	mv $(PKG_BUILD_DIR)/conf/T6.FullMessage.SimpleLogPacket*.cfg $(PKG_BUILD_DIR)/conf/T6-full-message.cfg
	mv $(PKG_BUILD_DIR)/conf/T7.V2X_ALL_V01.cfg $(PKG_BUILD_DIR)/conf/T7-v2x.cfg
endef
Hooks/Prepare/Pre += prepare_source_directory


include $(INCLUDE_DIR)/package.mk

define Package/qlog
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+librt +libstdcpp
  TITLE:=QLog modem diagnostic log capture tool for Quectel devices
endef

define Package/qlog/description
  Quectel QLog captures raw diagnostic (QMDL) logs from a Quectel cellular
  module's USB/PCIe diag port for offline analysis (QCAT/QXDM or scat).
  Ships Quectel's pre-built filter profiles (OTA/data, registration/context
  activation, simple data, throughput, full message, 5G NR/V2X) under
  /usr/share/qlog/conf/.
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
	$(INSTALL_DIR) $(1)/usr/share/qlog/conf
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/conf/*.cfg $(1)/usr/share/qlog/conf/
endef

$(eval $(call BuildPackage,qlog))
