# OpenWrt package definitions for the wwand connection manager.
# One source package (git: ddimension/wwand), three binary packages:
# wwand (ucode daemon), ucode-mod-wwand-io (native C transport module)
# and wwand-esim. Bump PKG_SOURCE_VERSION (and PKG_SOURCE_DATE) to pick
# up new source commits.

include $(TOPDIR)/rules.mk

PKG_NAME:=wwand
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ddimension/wwand.git
PKG_SOURCE_VERSION:=cc2e14da8ab8a092122e2d1e2bdc30d3ddac05c0
PKG_SOURCE_DATE:=2026-07-24
PKG_MIRROR_HASH:=1b9c070906afe8d15bc03bf886a1bc938c92bf4cbf73a17dfb1a69ffde678d5a

PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

# The native module's cmake tree is the io/ subdir of the source tree; build
# out-of-tree so cmake artifacts stay out of the source checkout. The ucode
# side (src-ucode/, files/) installs straight from PKG_BUILD_DIR and needs no
# compile step.
CMAKE_SOURCE_SUBDIR:=io
CMAKE_BINARY_SUBDIR:=build

define Package/wwand
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WWAN
  TITLE:=Event-driven QMI connection manager
  DEPENDS:=+ucode +ucode-mod-fs +ucode-mod-struct +ucode-mod-uloop \
	+ucode-mod-ubus +ucode-mod-uci +ucode-mod-rtnl +ucode-mod-wwand-io \
	+kmod-usb-net-qmi-wwan +kmod-rmnet
  CONFLICTS:=qmi-advanced uqmi
endef

define Package/wwand/description
  wwand is an event-driven connection manager daemon for QMI modems,
  supporting multiple modems and multiple parallel PDP contexts via QMAP
  multiplexing (rmnet and qmimux backends). It replaces the bash-based
  qmi-advanced package. Implemented in ucode; talks QMI natively over
  /dev/cdc-wdmX without spawning uqmi/qmicli.
endef

define Package/ucode-mod-wwand-io
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=ucode
  TITLE:=Message-oriented cdc-wdm/tty I/O module for wwand
  DEPENDS:=+libucode
endef

define Package/ucode-mod-wwand-io/description
  Minimal native ucode extension providing non-blocking, message-oriented
  I/O on QMI control devices (/dev/cdc-wdmX) and raw tty access for AT
  commands. Used by the wwand connection manager.
endef

define Package/ucode-mod-wwand-io/install
	$(INSTALL_DIR) $(1)/usr/lib/ucode
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/wwand_io.so $(1)/usr/lib/ucode/
endef

define Package/wwand/install
	$(INSTALL_DIR) $(1)/usr/share/ucode/wwand/codec/schema
	$(INSTALL_DIR) $(1)/usr/share/ucode/wwand/codec/mbim-schema
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/*.uc $(1)/usr/share/ucode/wwand/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/codec/*.uc $(1)/usr/share/ucode/wwand/codec/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/codec/schema/*.uc $(1)/usr/share/ucode/wwand/codec/schema/
	# daemon.uc imports the MBIM modules at top level, so the MBIM schema must
	# ship too, otherwise the daemon fails to compile modem_mbim.uc/context_mbim.uc
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/codec/mbim-schema/*.uc $(1)/usr/share/ucode/wwand/codec/mbim-schema/
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src-ucode/main.uc $(1)/usr/sbin/wwand
	rm -f $(1)/usr/share/ucode/wwand/main.uc
	# esim.uc + esim_bridge.uc ship in the optional wwand-esim package
	rm -f $(1)/usr/share/ucode/wwand/esim.uc
	rm -f $(1)/usr/share/ucode/wwand/esim_bridge.uc
	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/wwand-proto.sh $(1)/lib/netifd/proto/qmi.sh
	$(INSTALL_DIR) $(1)/usr/libexec/wwand
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/wwand-migrate $(1)/usr/libexec/wwand/migrate
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/wwand.init $(1)/etc/init.d/wwand
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/wwand.config $(1)/etc/config/wwand
	$(INSTALL_DIR) $(1)/etc/hotplug.d/usbmisc
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/wwand.hotplug $(1)/etc/hotplug.d/usbmisc/20-wwand
	# net hotplug: NCM modems (no cdc-wdm) + re-enumeration after a mode switch
	$(INSTALL_DIR) $(1)/etc/hotplug.d/net
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/wwand.hotplug.net $(1)/etc/hotplug.d/net/20-wwand
endef

define Package/wwand/conffiles
/etc/config/wwand
endef

define Package/wwand-esim
  SECTION:=net
  CATEGORY:=Network
  TITLE:=eSIM (eUICC) profile management for wwand
  # wwand-lpac is our self-contained static lpac (bundled wolfSSL+libcurl, no
  # OpenSSL/mbedtls .so). It drives the SM-DP+ download/notification (ES9+
  # HTTPS on the router); the daemon bridges lpac's stdio APDU protocol inline
  # (native, no wrapper script / jsonfilter).
  DEPENDS:=+wwand +wwand-lpac
endef

define Package/wwand-esim/description
 Optional ES10c (SGP.22) profile management for wwand: EID, profile list,
 enable/disable/delete over the modem UIM APDU channel. SM-DP+ profile
 downloads and notification acknowledgements are driven by lpac: its ES10
 APDUs are relayed through wwand's own APDU channel (ubus modem_apdu) by the
 stdio bridge, so wwand stays the sole owner of the modem — no separate AT
 port. lpac runs the ES9+ HTTPS on the router; no dedicated modem APN is
 required.

 The download is handled by the wwand-lpac package (a dependency): a single
 self-contained ~0.9 MB lpac binary with a minimal static wolfSSL + libcurl
 linked in, so it needs no libcurl/libssl/libcrypto .so (vs the ~6.4 MB that
 stock libcurl+OpenSSL pulls in) and carries the GSMA-capable TLS + the v2.3.0
 stdio-driver fix (upstream PR #399) itself. See wwand-lpac/Makefile.
endef

define Package/wwand-esim/install
	$(INSTALL_DIR) $(1)/usr/share/ucode/wwand
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/esim.uc $(1)/usr/share/ucode/wwand/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/esim_bridge.uc $(1)/usr/share/ucode/wwand/
endef

$(eval $(call BuildPackage,wwand))
$(eval $(call BuildPackage,ucode-mod-wwand-io))
$(eval $(call BuildPackage,wwand-esim))
