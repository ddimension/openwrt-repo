# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2026 Andre Valentin

include $(TOPDIR)/rules.mk

PKG_NAME:=heatingrod
PKG_VERSION:=3.0.0
PKG_RELEASE:=1

# Bundled source tarball of the rust/ workspace (see files/ + the
# make-src-tarball instructions in the heatingrod repository). No URL:
# the source is unpacked straight from files/ like qfirehose does.
PKG_SOURCE_FILE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_TOPDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=bb3defdef6cc296a5b42a0fd0a4a439ade34515b8b4779c6d7d03586ae133450

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Andre Valentin <avalentin@marcant.net>

# Rust toolchain from the packages feed (rust/host builds rustc + the
# target std; CARGO_HOME lives in DL_DIR so crate downloads are cached
# like every other source download).
PKG_BUILD_DEPENDS:=rust/host
PKG_BUILD_PARALLEL:=1

# Workspace: the binary crate is crates/heatingrod
MAKE_PATH:=crates/heatingrod

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk

# Two binaries: the daemon (crates/heatingrod) and the I2C failsafe
# (tools/dac-safe — the OpenWrt equivalent of the systemd ExecStopPost).
define Build/Compile
	$(call Build/Compile/Cargo,crates/heatingrod)
	$(call Build/Compile/Cargo,tools/dac-safe)
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR) $(PKG_BUILD_DIR).unpack
	mkdir -p $(PKG_BUILD_DIR).unpack
	tar -xJf $(CURDIR)/files/$(PKG_SOURCE_FILE) -C $(PKG_BUILD_DIR).unpack
	mv $(PKG_BUILD_DIR).unpack/$(PKG_SOURCE_TOPDIR) $(PKG_BUILD_DIR)
	rm -rf $(PKG_BUILD_DIR).unpack
	$(Build/Patch)
endef

define Package/heatingrod
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=PV-surplus heating rod controller (ESPHome API server)
  URL:=https://homeassistant.kalnet.hooya.de
  # 1-Wire runs over kernel w1 (sysfs) since 2026-09-04 — ds2490 is the
  # DS1490F USB master driver, w1_therm the DS18B20 slave driver.
  DEPENDS:=$(RUST_ARCH_DEPENDS) +kmod-w1 +kmod-w1-master-ds2490 +kmod-w1-slave-therm
endef

define Package/heatingrod/description
  Controller v3 (Rust): drives a 7.5kW heating rod from PV surplus over an
  analog 0-10V thyristor controller, implements the ESPHome Native API as
  a SERVER (Home Assistant integration), reads the grid power via ESPHome
  client, the DS100 Modbus meter, SOREL CAN bus and 1-Wire sensors (kernel
  w1, modules loaded by the init script).
  Musl-native: journald logging falls back to stderr.
endef

define Package/heatingrod/conffiles
/etc/heatingrod/config.yaml
endef

define Package/heatingrod/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d $(1)/etc/heatingrod
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/bin/* $(1)/usr/bin/
	$(INSTALL_BIN) ./files/heatingrod.init $(1)/etc/init.d/heatingrod
	$(INSTALL_CONF) ./files/config.yaml $(1)/etc/heatingrod/config.yaml
endef

$(eval $(call BuildPackage,heatingrod))
