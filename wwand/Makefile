# OpenWrt package definitions for the wwand connection manager.
# One source package (git: ddimension/wwand); the ucode side is split into a
# backend-neutral base plus per-backend packages so an install carries only the
# control protocols it needs:
#   wwand            - daemon + shared core + codec/client (no backend on its own)
#   wwand-qmi        - QMI backend            (DEPENDS wwand)
#   wwand-mbim       - MBIM backend           (DEPENDS wwand-qmi: the MBIM
#                                              QMI-over-MBIM passthrough reuses
#                                              qmi_backend)
#   wwand-ncm        - NCM/ECM backend        (DEPENDS wwand)
#   wwand-esim       - eSIM management        (DEPENDS wwand-qmi + wwand-lpac)
#   ucode-mod-wwand-io - native C transport module
# A typical QMI router installs `wwand-qmi` (which pulls in `wwand`); add
# `wwand-mbim` / `wwand-ncm` for those modems.
#
# NOTE: the split needs the ucode source that lazy-loads every backend
# (qmi_lazy.uc + the backend-neutral daemon). Bump PKG_SOURCE_VERSION (and
# PKG_SOURCE_DATE / PKG_MIRROR_HASH) to a wwand commit that includes them.

include $(TOPDIR)/rules.mk

PKG_NAME:=wwand
PKG_RELEASE:=22

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ddimension/wwand.git
PKG_SOURCE_VERSION:=d315595dd0fd651b2597d0a897542fa40fa84b48
PKG_SOURCE_DATE:=2026-08-14
PKG_MIRROR_HASH:=57cae1e444a6cb03c9bfa4b83fdff6f273fa846ec2491d5053840e3f1bd7eef5

PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

# The native module's cmake tree is the io/ subdir of the source tree; build
# out-of-tree so cmake artifacts stay out of the source checkout. The ucode
# side (src-ucode/, files/) installs straight from PKG_BUILD_DIR and needs no
# compile step.
CMAKE_SOURCE_SUBDIR:=io
CMAKE_BINARY_SUBDIR:=build

UCDIR:=/usr/share/ucode/wwand

# ---------------------------------------------------------------------------
# base: daemon + framework + codec/client + shared core. No backend on its own;
# the daemon loads whichever wwand-qmi/-mbim/-ncm package is present.
# ---------------------------------------------------------------------------
define Package/wwand
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WWAN
  TITLE:=Event-driven cellular connection manager (backend-neutral core)
  DEPENDS:=+ucode +ucode-mod-fs +ucode-mod-struct +ucode-mod-uloop \
	+ucode-mod-ubus +ucode-mod-uci +ucode-mod-rtnl +ucode-mod-wwand-io
endef

define Package/wwand/description
  wwand is an event-driven connection manager daemon for cellular modems,
  supporting multiple modems and multiple parallel PDP contexts. This base
  package carries the daemon, the netifd proto shim, the QMI codec (qmux/tlv +
  service schemas), the generic service client, the SIM/APDU layer and the
  shared modem/context core. Install a backend package (wwand-qmi, wwand-mbim
  or wwand-ncm) for the control protocols your modems use.
endef

define Package/wwand/install
	$(INSTALL_DIR) $(1)$(UCDIR)/codec/schema
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/*.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/codec/*.uc $(1)$(UCDIR)/codec/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/codec/schema/*.uc $(1)$(UCDIR)/codec/schema/
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src-ucode/main.uc $(1)/usr/sbin/wwand
	# wwandctl: the human-friendly CLI front-end over the ubus API
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src-ucode/wwandctl.uc $(1)/usr/bin/wwandctl
	# strip out the files that belong to the per-backend + esim packages
	rm -f $(1)$(UCDIR)/main.uc $(1)$(UCDIR)/wwandctl.uc
	# QMI backend -> wwand-qmi
	rm -f $(1)$(UCDIR)/modem.uc $(1)$(UCDIR)/context.uc \
		$(1)$(UCDIR)/qmi_backend.uc $(1)$(UCDIR)/callend.uc $(1)$(UCDIR)/qmi_lazy.uc
	# MBIM backend -> wwand-mbim (incl. the MBIM codec + schema)
	rm -f $(1)$(UCDIR)/modem_mbim.uc $(1)$(UCDIR)/context_mbim.uc \
		$(1)$(UCDIR)/mbim_backend.uc $(1)$(UCDIR)/mbim_client.uc \
		$(1)$(UCDIR)/qmi_over_mbim.uc $(1)$(UCDIR)/mbim_lazy.uc \
		$(1)$(UCDIR)/codec/mbim.uc
	# NCM backend -> wwand-ncm
	rm -f $(1)$(UCDIR)/modem_ncm.uc $(1)$(UCDIR)/context_ncm.uc $(1)$(UCDIR)/ncm_lazy.uc
	# eSIM -> wwand-esim
	rm -f $(1)$(UCDIR)/esim.uc $(1)$(UCDIR)/esim_bridge.uc
	$(INSTALL_DIR) $(1)/lib/netifd/proto
	# the shim registers `wwand`; the legacy `qmi` alias only when the global
	# `option takeover` is set (default off, so uqmi keeps `proto qmi`). Install
	# under the current name — the historical qmi.sh belonged to uqmi/qmi-advanced
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/wwand-proto.sh $(1)/lib/netifd/proto/wwand.sh
	$(INSTALL_DIR) $(1)/usr/libexec/wwand
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/wwand-migrate $(1)/usr/libexec/wwand/migrate
	# migration is user-triggered (LuCI modem list / the migrate CLI); the
	# uci-defaults hook auto-migrates on install/upgrade ONLY when the global
	# `option takeover` is set (default off — wwand does not touch existing configs)
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/wwand.defaults $(1)/etc/uci-defaults/99-wwand-migrate
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/wwand.init $(1)/etc/init.d/wwand
	# no /etc/config/wwand for new installs — all config lives in
	# /etc/config/network now (existing files survive upgrade and are still read).
	# files/wwand.config is kept in the source tree only as a documented example.
	$(INSTALL_DIR) $(1)/etc/hotplug.d/usbmisc
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/wwand.hotplug $(1)/etc/hotplug.d/usbmisc/20-wwand
	# net hotplug: NCM modems (no cdc-wdm) + re-enumeration after a mode switch
	$(INSTALL_DIR) $(1)/etc/hotplug.d/net
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/wwand.hotplug.net $(1)/etc/hotplug.d/net/20-wwand
	# tty hotplug: AT ports appearing after the datapath netdev (vendor-serial
	# new_id bind / late kmodloader) re-kick a modem parked in no_at_port backoff
	$(INSTALL_DIR) $(1)/etc/hotplug.d/tty
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/wwand.hotplug.tty $(1)/etc/hotplug.d/tty/20-wwand
	# wwan-framework hotplug: PCIe/MHI (and some USB) modems expose their control
	# port under /sys/class/wwan (/dev/wwanXqmiN|mbimN), not usbmisc/cdc-wdm
	$(INSTALL_DIR) $(1)/etc/hotplug.d/wwan
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/wwand.hotplug.wwan $(1)/etc/hotplug.d/wwan/20-wwand
endef

# ---------------------------------------------------------------------------
# wwand-qmi: the QMI backend (native qmux over /dev/cdc-wdmX).
# ---------------------------------------------------------------------------
define Package/wwand-qmi
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WWAN
  TITLE:=QMI backend for wwand
  DEPENDS:=+wwand +kmod-usb-net-qmi-wwan +kmod-rmnet
  # coexists with the stock OpenWrt QMI stack (uqmi + the qmi-advanced dialer):
  # by default wwand claims only `proto wwand` interfaces, so both can be
  # installed. Set the global `option takeover '1'` (or migrate interfaces from
  # the LuCI modem list) to hand `proto qmi` interfaces to wwand.
endef

define Package/wwand-qmi/description
  QMI control backend for wwand: talks QMI natively over /dev/cdc-wdmX (qmi_wwan
  driver) with QMAP multiplexing (rmnet), without spawning uqmi/qmicli. This is
  the common case for most cellular routers.
endef

define Package/wwand-qmi/install
	$(INSTALL_DIR) $(1)$(UCDIR)
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/modem.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/context.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/qmi_backend.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/callend.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/qmi_lazy.uc $(1)$(UCDIR)/
endef

# ---------------------------------------------------------------------------
# wwand-mbim: the MBIM backend. Depends on wwand-qmi because the QMI-over-MBIM
# passthrough runs the QMI stack (qmi_backend) over the open MBIM channel.
# ---------------------------------------------------------------------------
define Package/wwand-mbim
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WWAN
  TITLE:=MBIM backend for wwand
  DEPENDS:=+wwand-qmi +kmod-usb-net-cdc-mbim
  # coexists with the stock OpenWrt MBIM stack (netifd `mbim` proto, package
  # umbim): wwand manages a cdc_mbim modem only once its interface has been
  # migrated to `proto wwand` (LuCI modem list / migrate CLI), so both stacks can
  # be installed side by side.
endef

define Package/wwand-mbim/description
  MBIM control backend for wwand (cdc_mbim driver): native MS Basic Connect (+
  Extensions v2/v3) plus a QMI-over-MBIM passthrough that tunnels the whole QMI
  stack over the open MBIM channel for full CDC-level telemetry/config. The
  passthrough reuses qmi_backend, hence the dependency on wwand-qmi.
endef

define Package/wwand-mbim/install
	$(INSTALL_DIR) $(1)$(UCDIR)/codec/mbim-schema
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/modem_mbim.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/context_mbim.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/mbim_backend.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/mbim_client.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/qmi_over_mbim.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/mbim_lazy.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/codec/mbim.uc $(1)$(UCDIR)/codec/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/codec/mbim-schema/*.uc $(1)$(UCDIR)/codec/mbim-schema/
endef

# ---------------------------------------------------------------------------
# wwand-ncm: the NCM/ECM backend (cdc_ncm / cdc_ether, AT-controlled).
# ---------------------------------------------------------------------------
define Package/wwand-ncm
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WWAN
  TITLE:=NCM/ECM backend for wwand
  DEPENDS:=+wwand +kmod-usb-net-cdc-ncm +kmod-usb-net-cdc-ether
  # coexists with the stock OpenWrt NCM stack (netifd `ncm` proto, package
  # comgt-ncm): wwand drives an AT/NCM modem only once its interface has been
  # migrated to `proto wwand` (LuCI modem list / migrate CLI), so both stacks can
  # be installed side by side.
endef

define Package/wwand-ncm/description
  NCM/ECM control backend for wwand: an AT-controlled datapath over a plain
  cdc_ncm / cdc_ether netdev, for modems that expose no cdc-wdm control device.
endef

define Package/wwand-ncm/install
	$(INSTALL_DIR) $(1)$(UCDIR)
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/modem_ncm.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/context_ncm.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/ncm_lazy.uc $(1)$(UCDIR)/
endef

# ---------------------------------------------------------------------------
# ucode-mod-wwand-io: native C transport module.
# ---------------------------------------------------------------------------
define Package/ucode-mod-wwand-io
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=ucode
  TITLE:=Message-oriented cdc-wdm/tty I/O module for wwand
  # +ucode (not just +libucode): a .so under /usr/lib/ucode is unusable without
  # the interpreter, and +ucode already pulls +libucode. Matches the in-tree
  # UcodeModule macro (DEPENDS:=+ucode) used by all stock ucode-mod-* packages.
  DEPENDS:=+ucode
endef

define Package/ucode-mod-wwand-io/description
  Minimal native ucode extension providing non-blocking, message-oriented
  I/O on QMI control devices (/dev/cdc-wdmX) and raw tty access for AT
  commands. Used by the wwand connection manager.
endef

define Package/ucode-mod-wwand-io/install
	$(INSTALL_DIR) $(1)/usr/lib/ucode
	# use cmake.mk's exported binary dir (CMAKE_BINARY_SUBDIR above), not a
	# hardcoded build/, so changing the subdir can't silently break the install
	$(INSTALL_BIN) $(CMAKE_BINARY_DIR)/wwand_io.so $(1)/usr/lib/ucode/
endef

# ---------------------------------------------------------------------------
# wwand-esim: eSIM (eUICC) profile management. Needs a QMI UIM/APDU channel.
# ---------------------------------------------------------------------------
define Package/wwand-esim
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WWAN
  TITLE:=eSIM (eUICC) profile management for wwand
  # Needs an lpac binary at /usr/bin/lpac: either the generic openwrt-packages
  # lpac, or our self-contained static wwand-lpac (bundled wolfSSL+libcurl, no
  # OpenSSL/mbedtls .so — it PROVIDES lpac, so it satisfies +lpac too). lpac
  # drives the SM-DP+ download/notification (ES9+ HTTPS on the router); the
  # daemon bridges its stdio APDU protocol inline. APDU access uses the modem
  # UIM channel, so it also needs the QMI backend.
  DEPENDS:=+wwand-qmi +lpac
endef

define Package/wwand-esim/description
 Optional ES10c (SGP.22) profile management for wwand: EID, profile list,
 enable/disable/delete over the modem UIM APDU channel. SM-DP+ profile
 downloads and notification acknowledgements are driven by lpac: its ES10
 APDUs are relayed through wwand's own APDU channel (ubus modem_apdu) by the
 stdio bridge, so wwand stays the sole owner of the modem — no separate AT
 port. lpac runs the ES9+ HTTPS on the router; no dedicated modem APN is
 required.

 The download is handled by an lpac binary (the +lpac dependency): either the
 generic openwrt-packages lpac, or the self-contained wwand-lpac (which PROVIDES
 lpac) — a single ~0.9 MB binary with a minimal static wolfSSL + libcurl linked
 in, needing no libcurl/libssl/libcrypto .so (vs the ~6.4 MB stock libcurl+
 OpenSSL pulls in) and carrying the GSMA-capable TLS itself. Either works via
 /usr/bin/lpac; the stdio APDU bridge needs lpac >= 2.3.0 (upstream PR #399).
 See wwand-lpac/Makefile.
endef

define Package/wwand-esim/install
	$(INSTALL_DIR) $(1)$(UCDIR)
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/esim.uc $(1)$(UCDIR)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src-ucode/esim_bridge.uc $(1)$(UCDIR)/
endef

$(eval $(call BuildPackage,wwand))
$(eval $(call BuildPackage,wwand-qmi))
$(eval $(call BuildPackage,wwand-mbim))
$(eval $(call BuildPackage,wwand-ncm))
$(eval $(call BuildPackage,ucode-mod-wwand-io))
$(eval $(call BuildPackage,wwand-esim))
