#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=pcie_mhi
PKG_VERSION:=1.6.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

PKG_BUILD_PARALLEL:=1

define KernelPackage/pcie_mhi
  VARIANT:=plain
  SUBMENU:=WWAN Support
  TITLE:=Quectel PCIe MHI driver
  DEPENDS:=@PCI_SUPPORT
  CONFLICTS:=kmod-pcie_mhi_nss kmod-mhi-pci-generic
  FILES:=$(PKG_BUILD_DIR)/pcie_mhi.ko
  AUTOLOAD:=$(call AutoLoad,90,pcie_mhi)
endef

define KernelPackage/pcie_mhi/description
  Quectel PCIe MHI driver with QMI, MBIM, and AT ports.
endef

define KernelPackage/pcie_mhi_nss
  VARIANT:=nss
  SUBMENU:=WWAN Support
  TITLE:=Quectel PCIe MHI driver with NSS offload
  DEPENDS:=@(TARGET_qualcommax_ipq807x||TARGET_qualcommax_ipq50xx) \
	@PCI_SUPPORT +kmod-rmnet-nss
  CONFLICTS:=kmod-mhi-pci-generic
  FILES:=$(PKG_BUILD_DIR)/pcie_mhi.ko
endef

define KernelPackage/pcie_mhi_nss/description
  Quectel PCIe MHI driver with the OpenWrt NSS RMNET interface.
  The board or modem manager must load pcie_mhi after rmnet_nss.
endef

EXTRA_CFLAGS+= \
	-Wno-unused-function \
	-Wno-missing-prototypes \
	-Wno-missing-declarations

ifeq ($(BUILD_VARIANT),nss)
EXTRA_CFLAGS+= -I$(STAGING_DIR)/usr/include/qca-nss-rmnet -DCONFIG_QCA_NSS_DRV
endif

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(CP) ./LICENSE $(PKG_BUILD_DIR)/LICENSE
endef

define Build/Compile
	+$(KERNEL_MAKE) ccflags-y="$(EXTRA_CFLAGS)" M="$(PKG_BUILD_DIR)" \
		modules
endef

$(eval $(call KernelPackage,pcie_mhi))
$(eval $(call KernelPackage,pcie_mhi_nss))
