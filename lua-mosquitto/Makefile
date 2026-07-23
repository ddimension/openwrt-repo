include $(TOPDIR)/rules.mk

PKG_NAME:=lua-mosquitto
PKG_VERSION:=0.4.1.9.1
PKG_RELEASE:=1
PKG_MAINTAINER:=André Valentin <avalentin@marcant.net>

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/flukso/lua-mosquitto.git
PKG_SOURCE_VERSION:=46422c4d498254001407073426744c294ef1ea47
PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_MIRROR_HASH:=de67c3a77553c11794dbc36ab8774f48a411e00ce3b1d6198735d2c20e4b78f2

include $(INCLUDE_DIR)/package.mk

define Package/lua-mosquitto
	SUBMENU:=Lua
	SECTION:=lang
	CATEGORY:=Languages
	TITLE:=lua-mosquitto
	URL:=https://github.com/flukso/lua-mosquitto.git
	DEPENDS:=+lua +libmosquitto-ssl
endef

define Package/lua-mosquitto/description
	Mosquitto based MQTT ( http://mqtt.org/ ) client library for Lua. MQTT is a popular network communication protocol working by "publish/subscribe" model.
endef

define Package/lua-mosquitto/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/mosquitto.so $(1)/usr/lib/lua/mosquitto.so
endef

$(eval $(call BuildPackage,lua-mosquitto))
