#
# The Lua binding for ubus, with an asynchronous invoke.
#
# Why this exists as a package of its own rather than a patch to the base one:
# the stock libubus-lua only offers conn:call(), which runs ubus_invoke() and
# spins its own event loop until the answer arrives. In a daemon that already
# runs uloop — apman-status does, and answers RADIUS from the same loop — that
# blocks everything for as long as the peer takes. Measured on the fleet: a
# 'file exec sleep 5' sent by the controller froze the agent for five seconds,
# and with macaddr_acl=2 every station trying to associate in that window was
# turned away because nobody answered.
#
# It builds *only* lua/, out of the same ubus source at the same commit the base
# OpenWrt package pins. Nothing else that source can produce is built: no
# libubus, no ubusd, no cli. The module links against the libubus already in
# the staging tree — the one the base package built and the one that will be on
# the device — so there is never a second copy of the library and never a
# question which of them is in use.
#
# That is also why no ABI version is set here. -DABIVERSION only affects
# building libubus itself; we do not, and the SONAME our module records is
# whatever the base package produced. DEPENDS on +libubus carries the ABI
# pinning from there.
#
# The name is deliberately not libubus-lua: a second package under that name
# would be resolved by feed order, silently, and which one ends up in an image
# would depend on how the feeds were installed. This one PROVIDES it, so
# '+libubus-lua' dependencies still resolve, and CONFLICTS with it, because
# both write /usr/lib/lua/ubus.so.
#
# Updating it: match PKG_SOURCE_VERSION and PKG_SOURCE_DATE to the base ubus
# package of the OpenWrt release being built against, refresh the patch, and
# recompute PKG_MIRROR_HASH. Building against a source older or newer than the
# installed libubus is the one way to get this wrong quietly, so the commit is
# pinned to the base package's rather than to a branch.
#
# This is free software, licensed under the GNU Lesser General Public License
# version 2.1, like the source it patches.

include $(TOPDIR)/rules.mk

PKG_NAME:=libubus-lua-async
PKG_VERSION:=2026.06.28~24864e78
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://git.openwrt.org/project/ubus.git
PKG_SOURCE_DATE:=2026-06-28
PKG_SOURCE_VERSION:=24864e7840b3a02a9ef76284a373f6b2f00b8a9b
PKG_MIRROR_HASH:=84666618e7b4a260cd900248a6e3af930ac51011ab7019086986d62c7b7a2172

PKG_LICENSE:=LGPL-2.1
PKG_MAINTAINER:=Andre Valentin <avalentin@marcant.net>

CMAKE_INSTALL:=1
PKG_BUILD_FLAGS:=lto
PKG_ASLR_PIE_REGULAR:=1

# configure lua/ alone: it is a complete cmake project of its own, and pointing
# cmake at it skips the top level entirely
CMAKE_SOURCE_SUBDIR:=lua

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/libubus-lua-async
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Lua binding for the OpenWrt RPC client, with call_async
  URL:=https://git.openwrt.org/project/ubus.git
  DEPENDS:=+libubus +liblua
  PROVIDES:=libubus-lua
  CONFLICTS:=libubus-lua
endef

define Package/libubus-lua-async/description
The stock Lua binding plus conn:call_async(object, method, params, callback
[, timeout_seconds]): the request goes to the uloop the connection is already
attached to and the call returns at once. The callback runs exactly once with
(result_or_nil, status) — status is 0 on success and UBUS_STATUS_TIMEOUT (7)
when the deadline passed. Everything the stock binding does is unchanged.
endef

TARGET_CFLAGS += -I$(STAGING_DIR)/usr/include

# lua/CMakeLists.txt guards its target on BUILD_LUA, which the top level would
# normally have set
CMAKE_OPTIONS += \
	-DBUILD_LUA=ON \
	-DLUAPATH=/usr/lib/lua

define Package/libubus-lua-async/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/lua/ubus.so $(1)/usr/lib/lua/
endef

$(eval $(call BuildPackage,libubus-lua-async))
