#
# LuCI status page for the wwand modem daemon.
# Adds Status → Modem: a live signal / cell-environment view, useful for
# antenna alignment (peak-hold on RSRP/SINR).
#
# Sources live in https://github.com/ddimension/luci-app-wwand — bump
# PKG_SOURCE_VERSION (and PKG_SOURCE_DATE) to pick up new source commits.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-wwand
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ddimension/luci-app-wwand.git
PKG_SOURCE_VERSION:=7efacb15e3e5be2c8d64224c1467f6a08bfd4082
PKG_SOURCE_DATE:=2026-07-23
PKG_MIRROR_HASH:=skip

PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=

LUCI_TITLE:=Modem status page for wwand (signal / cell alignment)
LUCI_DEPENDS:=+wwand
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
