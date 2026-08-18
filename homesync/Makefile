#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=homesync
PKG_VERSION:=7
PKG_RELEASE:=2
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=Andre Valentin <avalentin@marcant.net>

include $(INCLUDE_DIR)/package.mk

# Runs on the Snapcast client from the official packages feed, whose binary
# package is named `snapclient` (this feed's own snapcast package, which
# called it snapcast-client, has been dropped in favour of it). homesync
# drives /usr/bin/snapclient from its own multi-instance UCI config; the
# stock /etc/config/snapclient ships disabled, so the two do not collide.
#
# snapclient sits in EXTRA_DEPENDS, not DEPENDS: this package only ships
# shell scripts, so pulling snapcast into the build just to compile a C++
# tree we never link against would be waste. EXTRA_DEPENDS lands in the
# package metadata alone, so apk still installs snapclient alongside.
define Package/homesync
  SECTION:=sound
  CATEGORY:=Sound
  TITLE:=Synchronised multiroom speaker setup (Snapcast client)
  DEPENDS:=+alsa-utils +kmod-usb-audio +kmod-usb-hid
  # >=0.32.0: that is where snapclient learned the positional server URL
  # the init script passes (older releases only take --host/--port).
  EXTRA_DEPENDS:=snapclient (>=0.32.0)
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
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/etc/init.d/homesync $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/etc/hotplug.d/usb/30-homesync-usb-audio $(1)/etc/hotplug.d/usb/
	$(INSTALL_CONF) ./files/etc/config/homesync $(1)/etc/config/
	$(INSTALL_BIN) ./files/usr/bin/homesync $(1)/usr/bin/
endef

$(eval $(call BuildPackage,homesync))
