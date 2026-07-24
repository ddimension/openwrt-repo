#
# LuCI network-manager protocol handler for the wwand modem daemon.
# Registers the 'qmi' protocol UI (replaces luci-proto-qmi — both install
# the same protocol/qmi.js path, so only one can be installed).
#
# Sources live in https://github.com/ddimension/luci-proto-wwand — bump
# PKG_SOURCE_VERSION (and PKG_SOURCE_DATE) to pick up new source commits.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-proto-wwand
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ddimension/luci-proto-wwand.git
PKG_SOURCE_VERSION:=7d50a381cd7b81c9a21fb1e52e18e9b5424f7eb8
PKG_SOURCE_DATE:=2026-07-23
PKG_MIRROR_HASH:=skip

PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=

LUCI_TITLE:=Support for QMI/5G cellular modems (wwand)
# luci-app-wwand provides the shared wwand.bands resource (band/frequency
# helpers) used by this handler; depending on it keeps a single source of
# truth. The status app has no file conflicts, so pulling it in is safe.
LUCI_DEPENDS:=+wwand +luci-app-wwand

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
