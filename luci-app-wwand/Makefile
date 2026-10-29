#
# LuCI status & settings app for the wwand modem daemon: the modem status page,
# the Modems editor, live settings, and the shared resources (wwand.bands /
# wwand.modemopts / wwand.simlist) reused by the proto handler.
#
# Sources live in https://github.com/ddimension/luci-app-wwand, tagged vX.Y.Z
# together with wwand. Pin a new commit with
# `scripts/bump-source.sh luci-app-wwand <tag|commit>`: it derives PKG_VERSION
# (X.Y.Z at a tag, X.Y.Z_pN after it), PKG_RELEASE and the mirror hash.
#
# NOTE: built from a git PKG_SOURCE, so it does NOT use luci.mk — luci.mk's
# htdocs/root install is gated on those dirs living next to the Makefile
# (in-tree), which yields an EMPTY package for a git-fetched source. We install
# explicitly from $(PKG_BUILD_DIR), like the wwand package in this feed.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-wwand
PKG_VERSION:=1.8.0_pre5
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ddimension/luci-app-wwand.git
PKG_SOURCE_VERSION:=ae9c68173257891efd30fd1229905cff27fa7230
PKG_MIRROR_HASH:=a95a103ab51f4e03ae37cb6b5a1783708e2072ad72c3e5e7636d779003689995

PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=

# po2lmo, for the translation packages below
PKG_BUILD_DEPENDS:=luci-base/host

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-wwand
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=wwand cellular modem status & settings
  DEPENDS:=+luci-base +wwand
  PKGARCH:=all
endef

define Package/luci-app-wwand/description
  LuCI status and configuration app for the wwand cellular modem daemon.
endef

define Build/Compile
endef

define Package/luci-app-wwand-statistics
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=wwand graphs for luci-app-statistics
  DEPENDS:=+luci-app-statistics +wwand
  PKGARCH:=all
endef

define Package/luci-app-wwand-statistics/description
  RRD graph definitions for the data `wwandctl collectd` feeds into collectd:
  signal strength, band power, quality, SINR, modem temperature and state, one
  line per radio technology.

  Split out because it drops a file into luci-app-statistics' own resource tree,
  which is only meaningful when that app is installed — luci-app-statistics
  lists that directory at runtime, so nothing over there has to know about us.

  Feeding it needs no extra package at all:

      config statistics 'collectd_exec'
              option enable '1'

      config collectd_exec_input
              option cmdline '/usr/bin/wwandctl collectd'
endef

# Named, not globbed. The same rule the wwand package follows for its ucode
# sources: a wildcard install silently ships whatever happens to be in the tree,
# so a file added for one package lands in another — which is exactly how the
# statistics graph definition would have been installed on boxes with no
# luci-app-statistics. A new resource has to be added here, and that is the
# point of listing them.
LUCI_WWAND_VIEW:=modems.js settings.js sims.js status.js
LUCI_WWAND_RES:=bands.js esim.js format.js graph.js logbox.js mccmnc.js \
	modemopts.js modemsid.js netsel.js rpc.js signal.svg simlist.js

define Package/luci-app-wwand/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/wwand
	$(INSTALL_DIR) $(1)/www/luci-static/resources/wwand
	for f in $(LUCI_WWAND_VIEW); do \
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/htdocs/luci-static/resources/view/wwand/$$$$f \
			$(1)/www/luci-static/resources/view/wwand/ ; \
	done
	for f in $(LUCI_WWAND_RES); do \
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/htdocs/luci-static/resources/wwand/$$$$f \
			$(1)/www/luci-static/resources/wwand/ ; \
	done
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/root/usr/share/luci/menu.d/luci-app-wwand.json \
		$(1)/usr/share/luci/menu.d/
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/root/usr/share/rpcd/acl.d/luci-app-wwand.json \
		$(1)/usr/share/rpcd/acl.d/
endef

define Package/luci-app-wwand-statistics/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/statistics/rrdtool/definitions
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/htdocs/luci-static/resources/statistics/rrdtool/definitions/wwand.js \
		$(1)/www/luci-static/resources/statistics/rrdtool/definitions/
endef

# Translations: one luci-i18n-wwand-<lang> per po/<lang>/wwand.po in the
# source. luci.mk finds the languages by listing po/ next to the Makefile while
# make parses it, and a git source is not there yet at that point — so they are
# named here, and a new translation needs its language (and its name, for
# LuCI's language list) added in the same bump that pins it. Named, like the
# files above: a language listed without its .po fails the build instead of
# shipping an empty package.
#
# Same package names, Kconfig defaults, .lmo names and luci.languages entry
# as luci.mk (feeds/luci luci.mk LuciTranslation, 2026-10): the .po directory
# is LuCI's language tag (pt_BR), the .lmo carries its short code where the two
# differ (LUCI_LC_ALIAS there). The entry matters: the language selector and
# the Accept-Language match read only luci.languages (luci-mod-system
# system.js, luci-base dispatcher.uc, 2026-10), and this package does not pull
# in the luci-i18n-base-<lang> that would otherwise write it.
LUCI_WWAND_LANGS:=
LUCI_WWAND_LC.bn_BD:=bn
LUCI_WWAND_LC.nb_NO:=no
LUCI_WWAND_LC.pt_BR:=pt-br
LUCI_WWAND_LC.zh_Hans:=zh-cn
LUCI_WWAND_LC.zh_Hant:=zh-tw
# LUCI_WWAND_NAME.<lang>:=<name as LUCI_LANG.<lang> in luci.mk>, e.g.
# LUCI_WWAND_NAME.pl:=Polski (Polish)

# 1: LuCI language code (package and .lmo name), 2: po directory
define LuciWwandTranslation
  define Package/luci-i18n-wwand-$(1)
    SECTION:=luci
    CATEGORY:=LuCI
    TITLE:=luci-app-wwand - $(1) translation
    HIDDEN:=1
    DEFAULT:=LUCI_LANG_$(2)||(ALL&&m)
    DEPENDS:=luci-app-wwand
    PKGARCH:=all
  endef

  define Package/luci-i18n-wwand-$(1)/description
    Translation for luci-app-wwand ($(2)).
  endef

  define Package/luci-i18n-wwand-$(1)/install
	$$(INSTALL_DIR) $$(1)/etc/uci-defaults
	echo "uci set luci.languages.$(subst -,_,$(1))='$(or $(LUCI_WWAND_NAME.$(2)),$(2))'; uci commit luci" \
		> $$(1)/etc/uci-defaults/luci-i18n-wwand-$(1)
	$$(INSTALL_DIR) $$(1)/usr/lib/lua/luci/i18n
	po2lmo $(PKG_BUILD_DIR)/po/$(2)/wwand.po \
		$$(1)/usr/lib/lua/luci/i18n/wwand.$(1).lmo
  endef

  LUCI_WWAND_I18N += luci-i18n-wwand-$(1)
endef

$(foreach lang,$(LUCI_WWAND_LANGS),$(eval $(call LuciWwandTranslation,$(or $(LUCI_WWAND_LC.$(lang)),$(lang)),$(lang))))

$(eval $(call BuildPackage,luci-app-wwand))
$(eval $(call BuildPackage,luci-app-wwand-statistics))
$(foreach pkg,$(LUCI_WWAND_I18N),$(eval $(call BuildPackage,$(pkg))))
