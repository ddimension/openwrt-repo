#
# LuCI network-manager protocol handler for the wwand modem daemon.
# Registers the 'wwand' protocol UI (protocol/wwand.js) plus the legacy 'qmi'
# alias (protocol/qmi.js). Because it installs protocol/qmi.js it replaces
# luci-proto-qmi — both install that path, so only one can be installed.
#
# Sources live in https://github.com/ddimension/luci-proto-wwand — bump
# PKG_SOURCE_VERSION (and PKG_SOURCE_DATE) to pick up new source commits.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-proto-wwand
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ddimension/luci-proto-wwand.git
PKG_SOURCE_VERSION:=e92329677519344d1158d6ede13e67106ac2f482
PKG_SOURCE_DATE:=2026-07-24
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
