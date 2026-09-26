#
# Remote SIM for wwand: a SIM card in a reader on the router — or on another
# machine over SSH — used by the modem as if it sat in its own slot, through
# Qualcomm's QMI UIM Remote service. A wwand PLUGIN (wwand plugins.uc), kept
# out of the wwand sources on purpose: it is not meant for upstream.
#
# Sources live in https://github.com/ddimension/wwand-rsim, tagged vX.Y.Z. Pin
# a new commit with `scripts/bump-source.sh wwand-rsim <tag|commit>`.
#
# The card-side helper rsim-card is C (the repo's helper/ subdirectory, CMake);
# the plugin and the wwandctl command are ucode, installed as they are. The
# LuCI page (luci/) is its own package, installed explicitly from
# $(PKG_BUILD_DIR) like luci-app-wwand-ipa.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=wwand-rsim
PKG_VERSION:=0.0.1_p16
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ddimension/wwand-rsim.git
PKG_SOURCE_VERSION:=7452f282b764743e75ecb381c362b8e0ee0e1de8
PKG_MIRROR_HASH:=b60bab36c43f3f7f125bba2ec88825d0aa13ea6c115f2c59c54ed4ea6a983c9c

PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

# the helper is the repo's helper/ subtree; PC/SC stays out of this package
# (the Smartmouse USB and Phoenix readers need none of it), libusb is for the
# Smartmouse USB, whose clock and mode are set and whose UART is driven over
# USB directly — no kernel serial driver needed
CMAKE_SOURCE_SUBDIR:=helper
CMAKE_BINARY_SUBDIR:=build
CMAKE_OPTIONS += \
	-DWITH_PCSC=OFF \
	-DWITH_LIBUSB=ON \
	-DBUILD_TESTING=OFF \
	-DRSIM_WERROR=OFF

# Beside the package: the same helper, linked statically, as a file the site
# hands out. A SIM host reached with `ssh:<user>@<host>:<reader>` runs
# `rsim-card` by name and needs nothing else of this project, so it should be
# able to fetch one file — build.yml collects $(BIN_DIR)/rsim-card into
# public/tools/<arch>/, publish-feed.sh puts it under tools/<channel>/<arch>/
# and the start page links it. It is NOT part of any .apk.
#
# x86_64 only, because that is what people plug a reader into; adding an arch
# is one more value here. The second CMake tree repeats the toolchain settings
# of include/cmake.mk rather than reusing Build/Configure/Default, which is
# bound to CMAKE_BINARY_DIR. RSIM_STATIC=ON (upstream 7452f28) takes the static
# pkg-config link lines, so libusb comes along — on musl it needs no udev, the
# reason the same switch cannot produce a static USB build on a glibc distro.
RSIM_STATIC_ARCHS:=x86_64

ifneq ($(filter $(ARCH),$(RSIM_STATIC_ARCHS)),)
  define Build/Compile/StaticTool
	mkdir -p $(PKG_BUILD_DIR)/build-static
	(cd $(PKG_BUILD_DIR)/build-static; \
		CFLAGS="$(TARGET_CFLAGS) $(TARGET_CPPFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		cmake \
			--no-warn-unused-cli \
			-DCMAKE_SYSTEM_NAME=Linux \
			-DCMAKE_SYSTEM_VERSION=1 \
			-DCMAKE_SYSTEM_PROCESSOR=$(ARCH) \
			-DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_C_FLAGS_RELEASE="-DNDEBUG" \
			-DCMAKE_C_COMPILER="$(CMAKE_C_COMPILER)" \
			-DCMAKE_AR="$(CMAKE_AR)" \
			-DCMAKE_NM="$(CMAKE_NM)" \
			-DCMAKE_RANLIB="$(CMAKE_RANLIB)" \
			-DCMAKE_FIND_ROOT_PATH="$(CMAKE_FIND_ROOT_PATH)" \
			-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
			-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
			-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
			-DCMAKE_PREFIX_PATH=$(STAGING_DIR) \
			-DCMAKE_SKIP_RPATH=TRUE \
			-DCMAKE_STRIP=: \
			-DRSIM_STATIC=ON \
			-DWITH_PCSC=OFF \
			-DWITH_LIBUSB=ON \
			-DBUILD_TESTING=OFF \
			-DRSIM_WERROR=OFF \
			$(CMAKE_SOURCE_DIR))
	+$(MAKE) -C $(PKG_BUILD_DIR)/build-static rsim-card
	$(INSTALL_DIR) $(BIN_DIR)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build-static/rsim-card $(BIN_DIR)/rsim-card
  endef
  Hooks/Compile/Post += Build/Compile/StaticTool
endif

UCDIR:=/usr/share/ucode/wwand

define Package/wwand-rsim
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WWAN
  TITLE:=Remote SIM (QMI UIM Remote) for wwand
  # wwand-qmi: the plugin allocates its UIM Remote client on the modem's QMI
  # channel (core dep qmi_client); libusb-1.0: the Smartmouse USB backend
  DEPENDS:=+wwand-qmi +libusb-1.0
endef

define Package/wwand-rsim/description
 Lets a Qualcomm modem use a SIM card that sits in a reader on the router,
 or on another machine reached over SSH, as if it were in the modem's own
 slot (QMI UIM Remote). Readers: Phoenix/Smartmouse serial readers, and the
 WB Electronics Smartmouse USB driven over libusb (clock and mode set by
 software). Configure per modem with `option rsim_reader` (phoenix:<tty>,
 wbsm:, or ssh:<user>@<host>:<reader>). The modem firmware must have the
 service enabled: `wwandctl rsim [modem] enable --reset` (Quectel).
 Another wwand modem can lend its card instead (`modem:<donor>`), over the
 SIM Access Profile or APDU by APDU (QMI UIM or AT+CSIM).
endef

define Package/luci-app-wwand-rsim
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Remote SIM page for wwand-rsim
  DEPENDS:=+luci-base +wwand-rsim
  PKGARCH:=all
endef

define Package/luci-app-wwand-rsim/description
 Network -> Remote SIM: per modem, where its SIM comes from (its own, a
 reader on the router or on another machine over SSH, or another modem
 lending its card), the state of the remote card, and the router's SSH key.
endef

define Package/wwand-rsim/install
	$(INSTALL_DIR) $(1)/usr/lib/wwand
	$(INSTALL_BIN) $(CMAKE_BINARY_DIR)/rsim-card $(1)/usr/lib/wwand/
	$(INSTALL_DIR) $(1)$(UCDIR)/plugins $(1)$(UCDIR)/ctl
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/plugins/rsim.uc $(1)$(UCDIR)/plugins/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/ctl/rsim.uc $(1)$(UCDIR)/ctl/
endef

# named, not globbed (the rule luci-app-wwand follows)
define Package/luci-app-wwand-rsim/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/wwand
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luci/htdocs/luci-static/resources/view/wwand/rsim.js \
		$(1)/www/luci-static/resources/view/wwand/
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luci/root/usr/share/luci/menu.d/luci-app-wwand-rsim.json \
		$(1)/usr/share/luci/menu.d/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luci/root/usr/share/rpcd/acl.d/luci-app-wwand-rsim.json \
		$(1)/usr/share/rpcd/acl.d/
endef

$(eval $(call BuildPackage,wwand-rsim))
$(eval $(call BuildPackage,luci-app-wwand-rsim))
