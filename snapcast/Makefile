include $(TOPDIR)/rules.mk

PKG_NAME:=snapcast
PKG_VERSION:=0.34.0
PKG_RELEASE=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/badaix/snapcast.git
PKG_SOURCE_VERSION:=v0.34.0
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MIRROR_HASH:=c037e4337abf36c85e4cd8082ed636e5da182d2c02d17360f0ba4160b0e5df1f

PKG_MAINTAINER:=Andre Valentin <avalentin@marcant.net>
# CMAKE_INSTALL:=1

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=

PKG_BUILD_PARALLEL:=1
PKG_BUILD_DEPENDS:=boost

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

TARGET_CFLAGS += -flto
TARGET_LDFLAGS += -flto

ifdef CONFIG_SNAPCAST_WITH_PULSE
	CMAKE_OPTIONS += -DBUILD_WITH_PULSE=1
	TARGET_LDFLAGS+= -Wl,-rpath-link=$(STAGING_DIR)/usr/lib/pulseaudio
	TARGET_LDFLAGS+= -Wl,-rpath-link=$(STAGING_DIR)/usr/lib/libiconv-full/lib
	TARGET_LDFLAGS+= -Wl,-rpath-link=$(STAGING_DIR)/usr/lib/libintl-full/lib
	TARGET_LDFLAGS += $(INTL_LDFLAGS) $(if $(INTL_FULL),-lintl)
else
	CMAKE_OPTIONS += -DBUILD_WITH_PULSE=0
endif

ifdef CONFIG_SNAPCAST_WITH_FLAC
	CMAKE_OPTIONS += -DBUILD_WITH_FLAC=1
else
	CMAKE_OPTIONS += -DBUILD_WITH_FLAC=0
endif

ifdef CONFIG_SNAPCAST_WITH_VORBIS
	CMAKE_OPTIONS += -DBUILD_WITH_VORBIS=1
else
	CMAKE_OPTIONS += -DBUILD_WITH_VORBIS=0
endif

ifdef CONFIG_SNAPCAST_WITH_TREMOR
	CMAKE_OPTIONS += -DBUILD_WITH_TREMOR=1
else
	CMAKE_OPTIONS += -DBUILD_WITH_TREMOR=0
endif

ifdef CONFIG_SNAPCAST_WITH_OPUS
	CMAKE_OPTIONS += -DBUILD_WITH_OPUS=1
else
	CMAKE_OPTIONS += -DBUILD_WITH_OPUS=0
endif

ifdef CONFIG_SNAPCAST_WITH_AVAHI
	CMAKE_OPTIONS += -DBUILD_WITH_AVAHI=1
else
	CMAKE_OPTIONS += -DBUILD_WITH_AVAHI=0
endif

ifdef CONFIG_SNAPCAST_WITH_EXPAT
	CMAKE_OPTIONS += -DBUILD_WITH_EXPAT=1
else
	CMAKE_OPTIONS += -DBUILD_WITH_EXPAT=0
endif

define Package/snapcast-server/config
        source "$(SOURCE)/Config.in"
endef

define Package/snapcast-client/config
        source "$(SOURCE)/Config.in"
endef

define Package/snapcast-server
  SECTION:=sound
  CATEGORY:=Sound
  TITLE:=snapcast server for multiroom audio playback
  DEPENDS:=+libstdcpp +AUDIO_SUPPORT:alsa-lib +libsoxr +libatomic +SNAPCAST_WITH_PULSE:pulseaudio-daemon-avahi +SNAPCAST_WITH_FLAC:libflac +SNAPCAST_WITH_VORBIS:libvorbis +SNAPCAST_WITH_VORBIS:libvorbisidec +SNAPCAST_WITH_OPUS:libopus +SNAPCAST_WITH_AVAHI:libavahi-client +SNAPCAST_WITH_EXPAT:libexpat +libopenssl 

endef

define Package/snapcast-client
  SECTION:=sound
  CATEGORY:=Sound
  TITLE:=snapcast client for multiroom audio playback
  DEPENDS:=+libstdcpp +AUDIO_SUPPORT:alsa-lib +libsoxr +libatomic +SNAPCAST_WITH_PULSE:pulseaudio-daemon-avahi +SNAPCAST_WITH_FLAC:libflac +SNAPCAST_WITH_VORBIS:libvorbis +SNAPCAST_WITH_VORBIS:libvorbisidec +SNAPCAST_WITH_OPUS:libopus +SNAPCAST_WITH_AVAHI:libavahi-client +SNAPCAST_WITH_EXPAT:libexpat +libopenssl
endef

define Package/snapcast-server/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/snapserver $(1)/usr/bin/
endef

define Package/snapcast-client/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/snapclient $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/hotplug.d/usb
	$(INSTALL_BIN) ./files/etc/init.d/snapcast $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/etc/hotplug.d/usb/30-snapcast-usb-audio $(1)/etc/hotplug.d/usb/
	$(INSTALL_CONF) ./files/etc/config/snapcast $(1)/etc/config/
endef

$(eval $(call BuildPackage,snapcast-server))
$(eval $(call BuildPackage,snapcast-client))
