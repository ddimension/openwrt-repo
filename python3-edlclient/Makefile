#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#
# Lean packaging of bkerler's edl toolkit, scoped to the qc_diag DIAG path
# (NV read/write, EFS read, DIAG->EDL reboot) that we need for the Chateau 5G
# RG650E bus-switch recovery. The heavy firehose/sahara/sierra deps
# (capstone, keystone-engine, paramiko, qrcode, passlib, Exscript) are NOT
# pulled in: qc_diag never imports them, and full-flash recovery is handled by
# the separate qfirehose package. If you later want the full `edl` firehose
# client on-device, add those deps and drop the qc_diag-only note below.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=python3-edlclient
PKG_VERSION:=2026.08.09
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/bkerler/edl.git
PKG_SOURCE_VERSION:=e4266d278728660a79f170d498dab3bb8ed641b1
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MIRROR_HASH:=5d1253ef6c8eeb43eab7e9eadad91c5d9923a800323cccdfb2faa82874fe75b7

PKG_MAINTAINER:=André Valentin <a.valentin@ddimension.net>
PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-version.mk

PYTHON3_PKG_DIR:=/usr/lib/python$(PYTHON3_VERSION)/site-packages

define Package/python3-edlclient
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=Python
  TITLE:=Qualcomm EDL/DIAG toolkit (bkerler edl), qc_diag-scoped
  URL:=https://github.com/bkerler/edl
  DEPENDS:=+python3-light \
           +python3-ctypes \
           +python3-logging \
           +python3-xml \
           +python3-pyusb \
           +python3-pyserial \
           +python3-colorama
endef

define Package/python3-edlclient/description
  bkerler's edl toolkit, packaged lean for the qc_diag DIAG interface:
  read/write Qualcomm NV items, read EFS, and reboot the modem into EDL over
  the USB DIAG port. Installs the `qc_diag` wrapper. Full firehose flashing is
  out of scope here (use the qfirehose package); the loaders and their
  disassembler deps are intentionally omitted.
endef

# Pure-Python payload; nothing to compile.
define Build/Compile
endef

define Package/python3-edlclient/install
	$(INSTALL_DIR) $(1)$(PYTHON3_PKG_DIR)/edlclient
	$(CP) $(PKG_BUILD_DIR)/edlclient/* $(1)$(PYTHON3_PKG_DIR)/edlclient/
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/qc_diag $(1)/usr/bin/qc_diag
endef

$(eval $(call BuildPackage,python3-edlclient))
