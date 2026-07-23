include $(TOPDIR)/rules.mk

PKG_NAME:=usb-relay-hid
PKG_VERSION:=2.2.0.1
PKG_RELEASE=0

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=https://github.com/OzFalcon/usb-relay-hid.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=d3a3fd21727c4aa370d3fe7b59f0386962353ffe
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MAINTAINER:=A. Valentin <avalentin@marcant.net
#PKG_MIRROR_HASH:=33991ba9d5b4fd71a188a708461c4b9b7f1f5998e2b99ffe418411af77c70e29

CMAKE_SOURCE_SUBDIR:=src
CMAKE_OPTIONS +=-DCMAKE_POLICY_VERSION_MINIMUM=3.5

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/usb-relay-hid
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libusb-compat
  TITLE:=Control hid usb relay
endef

define Package/usb-relay-hid/description
	Controll hid usb relays
endef

CMAKE_OPTIONS += \
	-DDEBUG=1

define Build/Install/Default
	echo "no install"
endef

define Package/usb-relay-hid/install
	$(INSTALL_DIR) $(1)/usr $(1)/usr/bin $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/hidusb-relay-cmd $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libhidusb-relay.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,usb-relay-hid))
