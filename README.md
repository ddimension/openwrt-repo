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

## Binary package repositories

CI ([build.yml](.github/workflows/build.yml)) builds the whole feed on every
push to `main` and publishes per-release/per-architecture binary
repositories to GitHub Pages:

```
https://ddimension.github.io/openwrt-repo/<release>/<arch>/
```

Currently built releases: **`snapshot`** (master) and **`openwrt-25.12`**.
Further OpenWrt release branches are added to the `release:` matrix in the
workflow as they appear and show up under the same URL scheme.

| Arch | Covers (among others) |
|---|---|
| `aarch64_cortex-a53` | qualcommax (MikroTik Chateau, ipq807x), mediatek/filogic, ipq60xx |
| `aarch64_cortex-a72` | bcm27xx/bcm2711 (Raspberry Pi 4) |
| `arm_cortex-a15_neon-vfpv4` | ipq806x |
| `arm_cortex-a7_neon-vfpv4` | ipq40xx |
| `mips_24kc` | ath79 (Ubiquiti) |
| `mipsel_24kc` | ramips/mt7621 |
| `x86_64` | x86/64 (VMs, APU, router PCs) |

On the device (apk — OpenWrt 25.12 and later, snapshots):

```
echo "https://ddimension.github.io/openwrt-repo/snapshot/aarch64_cortex-a53/packages.adb" \
  > /etc/apk/repositories.d/wwand.list
apk update
apk add wwand luci-app-wwand
```

Pick the `<release>/<arch>` matching the installed system.

### Signing

Repositories are signed once the corresponding repo secret is set;
until then install with `apk add --allow-untrusted`.

- **apk** (snapshot, 25.12+): ECDSA key. Generate with
  `openssl ecparam -name prime256v1 -genkey -noout -out private-key.pem`,
  store the file content as the `PRIVATE_KEY` repo secret, and commit the
  public half (`openssl ec -in private-key.pem -pubout -out
  keys/public-key.pem`) — the workflow publishes `keys/` at the site root;
  on devices install it into `/etc/apk/keys/`.
- **opkg** (releases ≤ 24.10, if ever added to the matrix): usign key via
  the `KEY_BUILD` secret.

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
Makefile, update `PKG_MIRROR_HASH` and increment `PKG_RELEASE`. The correct
mirror hash for a new source commit is printed by the failing CI check
("PKG_MIRROR_HASH does not match, set to <hash>"), or locally via
`make package/<name>/download package/<name>/check V=s` in an SDK.
