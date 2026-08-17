# openwrt-repo

OpenWrt **package feed** for the [wwand](https://github.com/ddimension/wwand)
cellular connection manager. This repo carries only the OpenWrt package
definitions (Makefiles, patches, packaging files); the actual sources live in
their own repositories and are fetched via `PKG_SOURCE_URL`.

## Packages

| Package | Source |
|---|---|
| `wwand` (binary packages `wwand`, `wwand-qmi`, `wwand-mbim`, `wwand-ncm`, `wwand-mhi`, `wwand-esim`) | https://github.com/ddimension/wwand |
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

The whole repository is **browsable** (static directory indexes are
generated on publish): [ddimension.github.io/openwrt-repo](https://ddimension.github.io/openwrt-repo/)

Currently built releases: **`snapshot`** (master) and **`openwrt-25.12`**
(openwrt-24.10 is no longer built). Further OpenWrt release branches are added to the
`release:` matrix in the workflow as they appear and show up under the same
URL scheme.

| Arch | Covers (among others) |
|---|---|
| `aarch64_cortex-a53` | qualcommax (MikroTik Chateau, ipq807x), mediatek/filogic, ipq60xx |
| `aarch64_cortex-a72` | bcm27xx/bcm2711 (Raspberry Pi 4) |
| `arm_cortex-a15_neon-vfpv4` | ipq806x |
| `arm_cortex-a7_neon-vfpv4` | ipq40xx |
| `mips_24kc` | ath79 (Ubiquiti) |
| `mipsel_24kc` | ramips/mt7621 |
| `x86_64` | x86/64 (VMs, APU, router PCs) |

On the device — apk (OpenWrt 25.12 and later, snapshots):

```
wget -O /etc/apk/keys/ddimension.pem https://ddimension.github.io/openwrt-repo/keys/ddimension.pem
echo "https://ddimension.github.io/openwrt-repo/snapshot/aarch64_cortex-a53/packages.adb" \
  > /etc/apk/repositories.d/wwand.list
apk update
apk add wwand luci-app-wwand
```

Pick the `<release>/<arch>` matching the installed system.

### Signing

Both signing keys are configured; the public halves live under
[`keys/`](keys/) and are published at the site root.

- **apk** (snapshot, 25.12+): ECDSA key (`keys/ddimension.pem`), private
  half in the `PRIVATE_KEY` repo secret. Install it on the device as
  `/etc/apk/keys/ddimension.pem` (any unique name — do NOT overwrite the
  stock `public-key.pem`); CI-built images bake in the same key. Regenerate with
  `openssl ecparam -name prime256v1 -genkey -noout -out private-key.pem`.
- **opkg** (usign key `keys/93f8441660b57edd.pub`, filename = key
  fingerprint, private half in the `KEY_BUILD` repo secret): kept for
  opkg-based releases; currently unused since openwrt-24.10 was dropped
  from the build matrix.

## Device firmware images

Besides the package feed, CI also builds **ready-to-flash firmware images**
with the **complete wwand stack baked in** (wwand + luci-app/proto-wwand +
wwand-lpac, plus umbim/mbim-utils, uqmi and the
cdc-mbim/qmi-wwan/rmnet kmods). Built for **master and stable** each, by
[build-device-images.yml](.github/workflows/build-device-images.yml):

| Device | `master` | `stable` | How |
|---|---|---|---|
| MikroTik Chateau 5G R17 ax | fork branch `pr-mikrotik-chateau-5g-r17-ax` | fork branch `chateau-stable-backport` | full buildroot (device only exists in the PR) |
| Zyxel NR7101 | `snapshot` | `openwrt-25.12` | ImageBuilder |
| Zyxel LTE3301-PLUS | `snapshot` | `openwrt-25.12` | ImageBuilder |

For the Zyxel devices the wwand packages are pulled **signed** from the
gh-pages feed above; the Chateau is a full toolchain build with wwand added
as a `src-git` feed.

**Triggers:** automatically after every successful feed run (`build`) on
`main`, and manually via
`gh workflow run build-device-images.yml -R ddimension/openwrt-repo --ref main`.

**Where the images live:** only as **GitHub Actions run artifacts** on the
respective run — `images-chateau-{master,stable}`,
`images-zyxel-{master,stable}` (retention **30 days**). There is **no
permanent URL** (unlike the package feed). Download the latest:

```
gh run download -R ddimension/openwrt-repo \
  $(gh run list -R ddimension/openwrt-repo -w build-device-images -L1 --json databaseId -q '.[0].databaseId') \
  -n images-zyxel-stable
```

Each artifact holds `<target>-<subtarget>-<base>/…-squashfs-sysupgrade.bin`
plus the `.manifest` (full package list, so you can verify the wwand stack).

## Licensing

The packaging in this repo (Makefiles, scripts) is GPL-2.0-only (see
[LICENSE](LICENSE)). Each package declares its own license via
`PKG_LICENSE` (verified against the upstream license files and source
headers). Of note: `qfirehose` and `qlog` are Quectel vendor code — their
NOTICE files permit use/redistribution **for Quectel customers**
(qfirehose: binary redistribution only); they are not open source in the
OSI sense.

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

The LuCI packages build with plain `package.mk` (deliberately not
`luci.mk`, which can't install from a git `PKG_SOURCE`); at runtime they
depend on `luci-base` from the standard `luci` feed.

## Local test builds (before burning CI)

Big builds should be validated locally first — same official `openwrt/sdk`
Docker containers, same checks as the workflow:

```
scripts/local-build.sh                            # full matrix (all releases × archs)
ARCHS=aarch64_cortex-a53 scripts/local-build.sh   # one arch
RELEASES=snapshot ARCHS=x86_64 PACKAGES="wwand" NPROC=4 scripts/local-build.sh
```

Prints `PASS:`/`FAIL:` per package and `COMBO PASS/FAIL` per release×arch;
on failure the exact compiler errors land in
`/tmp/openwrt-repo-local-build/<release>-<arch>/vbuild-<pkg>.log` (override
with `LOGDIR=`). Iterating is cheap: the SDK volume of a failed combo is
kept, so a fix only rebuilds the failed package; volumes of passing combos
are deleted automatically.

Pitfalls handled by the script (don't run the SDK container by hand without
them):

- **`--ulimit nofile=1024:1048576` is mandatory.** Docker's default
  (~unlimited) makes fakeroot/`apk mkpkg` burn minutes of 100% CPU *per
  package* (fd-close loop) — a build that should take minutes runs for
  hours, with `.faked.bin` pinned at 100% CPU.
- `openwrt/sdk` images are bootstrap images: `/builder/setup.sh` downloads
  the actual SDK on first start (hence the persistent volume).
- Any `kmod-*` dependency makes the SDK build package the whole
  kernel-module tree once per fresh volume (~30–40 min). That phase looks
  like a hang but isn't.

## Local device-image builds (chateau and other routers)

`scripts/local-image-build.sh` replicates the CI firmware-image build
(`build-device-images.yml` + `.github/ci/build-images.sh`) locally in the
same `openwrt-builder` container, using **podman** (preferred) or
**docker**. Default device is the MikroTik Chateau 5G R17 ax
(qualcommax/ipq60xx) with the complete wwand stack baked in; via options it
builds any device/architecture from any OpenWrt tree.

```
scripts/local-image-build.sh <release> [options] [-- <extra make-args>]

scripts/local-image-build.sh master                     # chateau, fork branch chateau-ci
scripts/local-image-build.sh stable -c ~/.cache/owrt    # 25.12 backport, with ccache
scripts/local-image-build.sh master -p "htop tcpdump"   # extra packages in the image
scripts/local-image-build.sh master --resume            # continue after a build error
scripts/local-image-build.sh master --resume -- V=s -j1 # find the actual error
scripts/local-image-build.sh openwrt-24.10 \            # other device, other arch
  --target ramips --subtarget mt7621 --device zyxel_nr7101
```

`<release>` maps to the source tree like the CI matrix: `master`/`snapshot`
→ fork branch `chateau-ci` (openwrt main + device support #24335 +
QCA8081 TX-clock fix #24566 + ath11k reboot fix #24601), `stable` → fork
branch `chateau-stable-backport` (25.12 + PR); anything else (e.g.
`openwrt-24.10`, `v24.10.2`) is fetched as branch/tag from upstream
`openwrt/openwrt.git` — the Chateau device does not exist there, so combine
it with `--device`. Override freely with `--src-url`/`--src-branch`.

Key options (full list: `--help`):

- `-p "pkg …"` — extra packages (`CONFIG_PACKAGE_x=y`); `--config FILE`
  appends arbitrary `.config` snippets; `--no-wwand` drops the wwand stack.
- `-c DIR` — cache dir: enables `CONFIG_CCACHE` on `DIR/ccache` and moves
  the download cache to `DIR/dl` (shareable across trees, like the CI's
  named volumes). Without it, no ccache and `dl/` lives in the work dir.
- **Resume:** the source tree incl. `build_dir`/`staging_dir` persists
  under `./build/<device>-<release>/src`, so every re-run is incremental.
  `--resume` additionally skips git sync/feeds/defconfig and jumps straight
  to `make` — the fast path after a failure (`git reset`/`feeds update`
  would otherwise trigger rebuilds). `--fresh` wipes the tree.
- `--image IMG` / `--engine podman|docker` — defaults:
  `image-registry.ddimension.net/myadmin/openwrt-builder:latest` (build it
  yourself from `~/projects/containers/openwrt-builder/` if you can't pull),
  podman preferred. Rootless podman runs with `--userns=keep-id`, docker
  with the host uid/gid, root falls back to uid 1000 + chown; SELinux hosts
  get `:z` mount labels automatically. The mandatory
  `--ulimit nofile` cap (see pitfalls above) is applied.
- `--testing-kernel` — `CONFIG_TESTING_KERNEL=y` (KERNEL_TESTING_PATCHVER),
  `--patch FILE` applies a patch after checkout.

Images land in `./build/<device>-<release>/out/<target>-<subtarget>/`
(override with `-o`); build logs in `…/src/logs/`. Expect several hours and
~40 GB for a first full toolchain build.

## Updating a package to a newer source commit

The source repos are pinned via `PKG_SOURCE_VERSION`. To release a new
version:

1. bump `PKG_SOURCE_VERSION` (and `PKG_SOURCE_DATE`) in the package's
   Makefile and increment `PKG_RELEASE`,
2. run **`scripts/update-hashes.sh <package>`** — it computes the matching
   `PKG_MIRROR_HASH` in the official SDK container (the only authoritative
   source; host-side tar/zstd replication has produced wrong values) and
   writes it into the Makefile,
3. commit both changes together.

CI runs gh-action-sdk in **per-package mode** (`PACKAGES`), which builds
only the listed packages plus their real dependencies and enforces the
mirror hash. Packages that exist in the feed but are not prebuilt
(snapcast, homesync) are not in the `PACKAGES` list and
additionally carry `@BROKEN` in their `DEPENDS` (build them locally with
`CONFIG_BROKEN=y`).
