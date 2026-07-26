#
# LuCI network-manager protocol handler for the wwand modem daemon.
# Registers the 'wwand' protocol UI (protocol/wwand.js) plus the legacy 'qmi'
# alias (protocol/qmi.js). Because it installs protocol/qmi.js it replaces
# luci-proto-qmi — both install that path, so only one can be installed.
#
# Sources live in https://github.com/ddimension/luci-proto-wwand — bump
# PKG_SOURCE_VERSION (and PKG_SOURCE_DATE) to pick up new source commits.
#
# NOTE: this is built from a git PKG_SOURCE, so it does NOT use luci.mk. luci.mk
# gates its htdocs/root install on those directories living NEXT TO the Makefile
# (in-tree); for a git-fetched source they only exist under $(PKG_BUILD_DIR), so
# luci.mk produces an EMPTY package. We install explicitly from $(PKG_BUILD_DIR),
# exactly like the wwand package in this feed.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-proto-wwand
PKG_RELEASE:=4

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ddimension/luci-proto-wwand.git
PKG_SOURCE_VERSION:=51985b822bca8d75b9cd3eb7cbdc665f1b8fed17
PKG_SOURCE_DATE:=2026-07-26
PKG_MIRROR_HASH:=6b3b29fb37108e3488474bcef66f13f6c5b3968a7c93e1f5a00950b302f01365

PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=

include $(INCLUDE_DIR)/package.mk

define Package/luci-proto-wwand
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=4. Protocols
  TITLE:=Support for QMI/5G cellular modems (wwand)
  # luci-app-wwand provides the shared wwand.bands resource (band/frequency
  # helpers) used by this handler; depending on it keeps a single source of truth.
  DEPENDS:=+luci-base +wwand +luci-app-wwand
  PKGARCH:=all
endef

define Package/luci-proto-wwand/description
  LuCI protocol handler for the wwand cellular modem daemon: the network-native
  'wwand' proto plus the legacy 'qmi' alias.
endef

define Build/Compile
endef

define Package/luci-proto-wwand/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/protocol
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/htdocs/luci-static/resources/protocol/*.js \
		$(1)/www/luci-static/resources/protocol/
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/root/usr/share/rpcd/acl.d/*.json \
		$(1)/usr/share/rpcd/acl.d/
endef

$(eval $(call BuildPackage,luci-proto-wwand))
