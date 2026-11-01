include $(TOPDIR)/rules.mk

PKG_NAME:=rmnet-nss
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

PKG_BUILD_PARALLEL:=1

define KernelPackage/rmnet-nss
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Devices
  TITLE:=RMNET support for Qualcomm NSS
  DEPENDS:=@(TARGET_qualcommax_ipq807x||TARGET_qualcommax_ipq50xx) \
	+kmod-qca-nss-drv +@NSS_DRV_RMNET_ENABLE +@NSS_DRV_C2C_ENABLE
  FILES:=$(PKG_BUILD_DIR)/rmnet_nss.ko
  AUTOLOAD:=$(call AutoLoad,42,rmnet_nss)
endef

define KernelPackage/rmnet-nss/description
  Connect vendor QMAP network interfaces to the Qualcomm NSS data path.
endef

EXTRA_CFLAGS+= -I$(STAGING_DIR)/usr/include/qca-nss-drv

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(CP) ./LICENSE $(PKG_BUILD_DIR)/LICENSE
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/qca-nss-rmnet
	$(CP) $(PKG_BUILD_DIR)/rmnet_nss.h $(1)/usr/include/qca-nss-rmnet/
endef

define Build/Compile
	+$(KERNEL_MAKE) ccflags-y="$(EXTRA_CFLAGS)" M="$(PKG_BUILD_DIR)" modules
endef

$(eval $(call KernelPackage,rmnet-nss))
