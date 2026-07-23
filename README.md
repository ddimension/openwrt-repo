# wwand-openwrt-repo

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

## Usage as a feed

Add to `feeds.conf` (or `feeds.conf.default`) of an OpenWrt buildroot or SDK:

```
src-git wwand https://github.com/ddimension/wwand-openwrt-repo.git
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
