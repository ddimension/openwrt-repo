#
# qrtr-lookup: lists the services on the Qualcomm IPC router (QRTR) bus, which is
# the first question when a PCIe/MHI modem's QMI lives on QRTR (wwand `device
# 'qrtr'`) and something does not show up.
#
# Only the lookup tool ships. The upstream qrtr-ns daemon is deliberately off:
# the kernel has its own name server (net/qrtr/af_qrtr.c:1309 starts it, linux
# 6.18.55) and upstream dropped the
# daemon after v1.2 (linux-msm/qrtr, src/ns.c gone at 29e36ae, 2026-09-15).
#
# Upstream sources: https://github.com/linux-msm/qrtr. Pin a new tag by hand:
# PKG_VERSION, PKG_SOURCE_VERSION (the commit, not the tag object), PKG_RELEASE,
# then scripts/update-hashes.sh qrtr.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qrtr
PKG_VERSION:=1.2
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/linux-msm/qrtr.git
PKG_SOURCE_VERSION:=b51ffaf22707b6000ecfb894c5b750f3bb7843b2
PKG_MIRROR_HASH:=d6fdfb9596d731a30bea7ff3737bcef428a01d8124ea12b2a75728b53c67aeab

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/meson.mk

MESON_ARGS += \
	-Dqrtr-ns=disabled \
	-Dsystemd-service=disabled

define Package/qrtr-lookup
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WWAN
  TITLE:=List the services on the Qualcomm IPC router bus
  URL:=https://github.com/linux-msm/qrtr
  DEPENDS:=+kmod-qrtr
endef

define Package/qrtr-lookup/description
 qrtr-lookup asks the kernel's QRTR name server for every registered service
 and prints node, port, service and instance, with the QMI service name where
 it knows one. For debugging modems whose QMI runs over QRTR on PCIe/MHI.
endef

# upstream's shared_library() ignores default_library, so libqrtr ships with it
define Package/qrtr-lookup/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/qrtr-lookup $(1)/usr/bin/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libqrtr.so.* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,qrtr-lookup))
