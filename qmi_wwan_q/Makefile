include $(TOPDIR)/rules.mk

PKG_NAME:=qmi_wwan_q
PKG_VERSION:=1.5.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=License.txt

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

PKG_BUILD_PARALLEL:=1

# Source: XT-Martinez/aw1000-feed a7e14ad (wwan/qmi_wwan_q), Quectel's
# qmi_wwan_q V1.5.0 by way of FUjr/QModem c49654e, which carries the Linux
# 6.17+ usbnet bh_work and hrtimer_setup changes. Built without its NSS hooks
# (no CONFIG_QCA_NSS_DRV), as there.
#
# No AUTOLOAD, unlike the aw1000-feed package: qmi_wwan_q and the stock
# qmi_wwan claim the same Quectel ids, and with both loaded at boot the one
# that binds first takes the modem. Here qmi_wwan keeps it; whoever wants the
# vendor driver unbinds the interface from qmi_wwan and loads this module
# with the qmap_mode it needs (the hwtest vendorqmap step does exactly that).

define KernelPackage/qmi_wwan_q
  SUBMENU:=WWAN Support
  TITLE:=Quectel vendor USB QMI WWAN driver (qmi_wwan_q)
  DEPENDS:=+kmod-usb-net +kmod-usb-wdm
  FILES:=$(PKG_BUILD_DIR)/qmi_wwan_q.ko
endef

define KernelPackage/qmi_wwan_q/description
  Quectel's vendor USB QMI WWAN driver with QMAP multiplexing: each mux channel
  is its own netdev, wwan0_1 .. wwan0_<qmap_mode>. Not loaded at boot; see
  README.md. With wwand, pair it with wwand-datapath-rmnet_nss.
endef

define KernelPackage/qmi_wwan_q/config
	config QMI_WWAN_Q_QMAP_MODE
		int "Default number of QMAP channels (qmap_mode)"
		depends on PACKAGE_kmod-qmi_wwan_q
		range 0 4
		default 2
		help
		  Default of the qmap_mode module parameter: the number of QMAP
		  channels (netdevs) the driver registers at probe.
endef

# Kbuild no longer reads EXTRA_CFLAGS (6.18), so these go in as ccflags-y.
MODULE_CFLAGS += \
	-Wno-unused-function \
	-Wno-missing-prototypes \
	-Wno-missing-declarations \
	-DQMI_WWAN_Q_DEFAULT_QMAP_MODE=$(if $(CONFIG_QMI_WWAN_Q_QMAP_MODE),$(CONFIG_QMI_WWAN_Q_QMAP_MODE),2)

define Build/Compile
	+$(KERNEL_MAKE) ccflags-y="$(MODULE_CFLAGS)" M="$(PKG_BUILD_DIR)" \
		modules
endef

$(eval $(call KernelPackage,qmi_wwan_q))
