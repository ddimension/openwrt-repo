#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=homesync
PKG_VERSION:=7
PKG_RELEASE:=3
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Andre Valentin <avalentin@marcant.net>

include $(INCLUDE_DIR)/package.mk

# Runs on the snapclient-mptcp package from this feed (the MPTCP variant
# of the Snapcast client from the ddimension/snapcast fork), which installs
# the binary as /usr/bin/snapclient - a drop-in for the stock snapclient.
# homesync drives /usr/bin/snapclient from its own multi-instance UCI
# config; the stock /etc/config/snapclient ships disabled, so the two do
# not collide.
#
# All dependencies are runtime-only and therefore EXTRA_DEPENDS: homesync
# ships shell scripts only, nothing is linked at build time, so staging the
# dependencies during the build would be pure waste (and would drag the
# snapcast C++ tree into CI). apk installs them alongside at runtime.
# ip-full provides the 'ip mptcp' subcommand used by the MPTCP hotplug
# scripts; busybox ip does not have it.
# >=0.32.0: that is where snapclient learned the positional server URL
# the init script passes (older releases only take --host/--port).
# Note: opkg-based releases (<= 24.10) ignore EXTRA_DEPENDS - this feed
# publishes apk repositories only.
define Package/homesync
  SECTION:=sound
  CATEGORY:=Sound
  TITLE:=Synchronised multiroom speaker setup (Snapcast client)
  EXTRA_DEPENDS:=alsa-utils kmod-usb-audio kmod-usb-hid ip-full snapclient-mptcp (>=0.32.0)
  PKGARCH:=all
endef

define Package/homesync/description
  Turns the device into a synchronised multiroom speaker: a UCI front end
  for the Snapcast client that starts one snapclient instance per configured
  server, plus a USB hotplug hook that restarts playback when a USB sound
  card appears or disappears.
endef

define Package/homesync/conffiles
/etc/config/homesync
endef

Build/Compile:=
Build/Configure:=

define Package/homesync/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/hotplug.d/usb
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/etc/init.d/homesync $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/etc/hotplug.d/usb/30-homesync-usb-audio $(1)/etc/hotplug.d/usb/
	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/30-mptcp-sta-kn5 $(1)/etc/hotplug.d/iface/
	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/30-mptcp-sta-kn2 $(1)/etc/hotplug.d/iface/
	$(INSTALL_CONF) ./files/etc/config/homesync $(1)/etc/config/
	$(INSTALL_BIN) ./files/usr/bin/homesync $(1)/usr/bin/
endef

$(eval $(call BuildPackage,homesync))
