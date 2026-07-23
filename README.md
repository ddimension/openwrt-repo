# openwrt-repo

OpenWrt **package feed** for the [wwand](https://github.com/ddimension/wwand)
cellular connection manager. This repo carries only the OpenWrt package
definitions (Makefiles, patches, packaging files); the actual sources live in
their own repositories and are fetched via `PKG_SOURCE_URL`.

## Packages

| Package | Source |
|---|---|
| `wwand` (binary packages `wwand`, `ucode-mod-wwand-io`, `wwand-esim`) | https://github.com/ddimension/wwand |
| `luci-app-wwand` | https://github.com/ddimension/luci-app-wwand |
| `luci-proto-wwand` | https://github.com/ddimension/luci-proto-wwand |
| `wwand-lpac` | upstream [estkme-group/lpac](https://github.com/estkme-group/lpac) (bundled static wolfSSL/curl) |
| `apman` | local (`files/`) — Lua AP manager (MQTT via lua-mosquitto, collectd integration) |
| `homesync` | local (`files/`) — snapcast-client based audio sync setup |
| `luacurl` | upstream [Lua-cURL/Lua-cURLv3](https://github.com/Lua-cURL/Lua-cURLv3) |
| `lua-mosquitto` | upstream [flukso/lua-mosquitto](https://github.com/flukso/lua-mosquitto) |
| `qfirehose` | upstream [nippynetworks/qfirehose](https://github.com/nippynetworks/qfirehose) (Quectel firmware flasher) |
| `qlog` | bundled Quectel QLog V1.5.8 source zip (modem debug logging) |
| `snapcast` | upstream [badaix/snapcast](https://github.com/badaix/snapcast) |
| `usb-relay-hid` | upstream [OzFalcon/usb-relay-hid](https://github.com/OzFalcon/usb-relay-hid) |

## Usage as a feed

Add to `feeds.conf` (or `feeds.conf.default`) of an OpenWrt buildroot or SDK:

```
src-git wwand https://github.com/ddimension/openwrt-repo.git
```

then:

```
./scripts/feeds update wwand
./scripts/feeds install -a -p wwand
```

The LuCI packages need the standard `luci` feed to be present (they include
`$(TOPDIR)/feeds/luci/luci.mk`).

## Updating a package to a newer source commit

The source repos are pinned via `PKG_SOURCE_VERSION`. To release a new
version, bump `PKG_SOURCE_VERSION` (and `PKG_SOURCE_DATE`) in the package's
Makefile and increment `PKG_RELEASE`.
