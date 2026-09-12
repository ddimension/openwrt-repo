# openwrt-repo

OpenWrt **package feed** for the [wwand](https://github.com/ddimension/wwand)
cellular connection manager and a few companions — signed binary repositories
for seven architectures on
[ddimension.github.io/openwrt-repo](https://ddimension.github.io/openwrt-repo/),
in two channels: **stable** (releases) and **main** (development). This repo
carries the OpenWrt package definitions; most sources live in their own
repositories, pinned to a commit.

## Packages

| Package | What it is | Binary packages | Source | CI |
|---|---|---|---|---|
| `wwand` | event-driven cellular connection manager (QMI, MBIM, NCM, PCIe/MHI), eSIM, scheduled APN tests | `wwand`, `wwand-qmi`, `wwand-mbim`, `wwand-ncm`, `wwand-mhi`, `wwand-esim`, `wwand-apntest`, `wwand-datapath-rmnet_nss`, `wwand-datapath-rmnet_nss_mhi` | [ddimension/wwand](https://github.com/ddimension/wwand) | ✓ |
| `luci-app-wwand` | LuCI modem status page, modem editor, live settings; the signal/statistics graphs as a separate package | `luci-app-wwand`, `luci-app-wwand-statistics` | [ddimension/luci-app-wwand](https://github.com/ddimension/luci-app-wwand) | ✓ |
| `luci-proto-wwand` | LuCI protocol handler for `proto wwand` interfaces | same | [ddimension/luci-proto-wwand](https://github.com/ddimension/luci-proto-wwand) | ✓ |
| `wwand-lpac` | lpac for eSIM profile management, static wolfSSL/curl | same | upstream [estkme-group/lpac](https://github.com/estkme-group/lpac) | ✓ |
| `ddimension-feed` | this feed's address and signing key, see [Set up a device](#set-up-a-device) | same | local (`files/`) | ✓ |
| `apman` | AP manager: ubus↔MQTT bridge, collectd plugin, on-AP RADIUS server ([apman/README.md](apman/README.md)) | same | [ddimension/apman-agent](https://github.com/ddimension/apman-agent) | ✓ |
| `libubus-lua-async` | the stock ubus Lua binding plus `conn:call_async()` | same | upstream [ubus](https://git.openwrt.org/project/ubus.git) | via `apman` |
| `homesync` | synchronised multiroom speaker: UCI front end for `snapclient-mptcp` | same | local (`files/`) | ✓ |
| `snapcast-mptcp` | Snapcast with Multipath-TCP | `snapserver-mptcp`, `snapclient-mptcp` | [ddimension/snapcast](https://github.com/ddimension/snapcast) | ✓ |
| `luacurl` | Lua binding for libcurl | same | upstream [Lua-cURL/Lua-cURLv3](https://github.com/Lua-cURL/Lua-cURLv3) | ✓ |
| `lua-mosquitto` | Lua binding for libmosquitto | same | upstream [flukso/lua-mosquitto](https://github.com/flukso/lua-mosquitto) | ✓ |
| `qfirehose` | Quectel QFirehose V1.4.21, firmware flasher | same | bundled source zip | ✓ |
| `qflash` | Quectel QFlash 2.0, legacy firmware flasher | same | bundled source tarball | ✓ |
| `qlog` | Quectel QLog V1.5.8, diagnostic log capture with Quectel's filter profiles | same | bundled source zip | ✓ |
| `usb-relay-hid` | control for cheap USB HID relay boards | same | upstream [OzFalcon/usb-relay-hid](https://github.com/OzFalcon/usb-relay-hid) | ✓ |
| `wpad-ieee8021x` | `ieee8021x` netifd protocol: wired 802.1X through wpa_supplicant's ubus interface | same | local (`files/`) | ✓ |
| `wpad-saeradh2e` | OpenWrt's full/OpenSSL wpad plus our SAE-over-RADIUS patches (also in [ddimension/hostapd](https://github.com/ddimension/hostapd) `sae-radius-h2e`) | same | OpenWrt `hostapd` + patches | ✓ |
| `heatingrod` | PV-surplus heating rod controller, Rust ([heatingrod/README.md](heatingrod/README.md)) | same | bundled snapshot of [heatingrod-controller](https://github.com/ddimension/heatingrod-controller) | — |
| `pcie_mhi` | Quectel PCIe/MHI host driver V1.3.8, ported to kernel 6.18 ([pcie_mhi/README.md](pcie_mhi/README.md)) | `kmod-pcie_mhi` | bundled source | — |
| `python3-edlclient` | Qualcomm EDL/DIAG toolkit, scoped to `qc_diag` | same | upstream [bkerler/edl](https://github.com/bkerler/edl) | — |

**CI**: ✓ = built and published for every architecture; the list is
[`.github/ci/packages`](.github/ci/packages). — = in the feed, deliberately not
built by CI: `heatingrod` builds rust/host from source (~35–45 GB build dir),
`pcie_mhi` does not get the RG650E past the MHI M0 handshake yet,
`python3-edlclient` is built on demand. Build those locally or in a buildroot.

## Binary package repositories

```
https://ddimension.github.io/openwrt-repo/<channel>/<release>/<arch>/
```

`<channel>` is `stable` or `main`, `<release>` the OpenWrt release
(`openwrt-25.12`, or `snapshot` for master). Per tree: **apk** is
`ddimension-feed.apk`, the feed's address and key for exactly that tree (see
[Set up a device](#set-up-a-device)); **tree** is the repository itself, browsable.

| Arch | Covers (among others) | stable · 25.12 | stable · snapshot | main · 25.12 | main · snapshot |
|---|---|---|---|---|---|
| `aarch64_cortex-a53` | qualcommax (MikroTik Chateau, ipq807x, ipq60xx), mediatek/filogic | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_cortex-a53/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_cortex-a53/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_cortex-a53/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_cortex-a53/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_cortex-a53/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_cortex-a53/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_cortex-a53/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_cortex-a53/) |
| `aarch64_cortex-a72` | bcm27xx/bcm2711 (Raspberry Pi 4) | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_cortex-a72/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_cortex-a72/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_cortex-a72/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_cortex-a72/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_cortex-a72/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_cortex-a72/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_cortex-a72/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_cortex-a72/) |
| `aarch64_generic` | rockchip/armv8 (RK33xx/RK35xx: Hinlink, NanoPi, Radxa) | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_generic/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_generic/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_generic/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_generic/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_generic/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_generic/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_generic/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_generic/) |
| `arm_cortex-a15_neon-vfpv4` | ipq806x | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/arm_cortex-a15_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/arm_cortex-a15_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/arm_cortex-a15_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/arm_cortex-a15_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/arm_cortex-a15_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/arm_cortex-a15_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/arm_cortex-a15_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/arm_cortex-a15_neon-vfpv4/) |
| `arm_cortex-a7_neon-vfpv4` | ipq40xx | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/arm_cortex-a7_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/arm_cortex-a7_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/arm_cortex-a7_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/arm_cortex-a7_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/arm_cortex-a7_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/arm_cortex-a7_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/arm_cortex-a7_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/arm_cortex-a7_neon-vfpv4/) |
| `mips_24kc` | ath79 (Ubiquiti) | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/mips_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/mips_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/mips_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/mips_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/mips_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/mips_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/mips_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/mips_24kc/) |
| `mipsel_24kc` | ramips/mt7621 (Zyxel NR7101, LTE3301-PLUS) | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/mipsel_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/mipsel_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/mipsel_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/mipsel_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/mipsel_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/mipsel_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/mipsel_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/mipsel_24kc/) |
| `x86_64` | x86/64 (VMs, APU, router PCs) | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/x86_64/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/x86_64/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/x86_64/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/x86_64/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/x86_64/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/x86_64/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/x86_64/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/x86_64/) |

The [start page](https://ddimension.github.io/openwrt-repo/) shows the same
table, generated from what is actually published. The **pre-channel path**
`…/<release>/<arch>/` stays valid: a copy of `stable/<release>/<arch>/`,
rewritten by every stable publish, so devices set up before the channels
existed keep working. Device images live under
[`images/`](https://ddimension.github.io/openwrt-repo/images/), signing keys
under [`keys/`](https://ddimension.github.io/openwrt-repo/keys/).

## How-tos

### Set up a device

The feed's address and key are themselves a package, `ddimension-feed`.
Install it once, **by name**, from the tree matching the channel, the
installed release and the architecture, and the device follows this feed from
then on — including any later change to the address or the key, which arrives
as an ordinary upgrade rather than as a note somebody has to act on.

```
apk --allow-untrusted \
  -X https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_cortex-a53/packages.adb \
  add ddimension-feed
apk update
apk add wwand luci-app-wwand
```

`--allow-untrusted` is needed exactly once and only for this package: it is the
moment the key is established. Everything afterwards, this package included, is
signed and verified. The `apk update` is needed once so apk fetches the index
the new `.list` names (the package cannot do it itself: its install runs while
apk holds the database lock).

From a downloaded `ddimension-feed.apk` (the **apk** links above) it works too,
with one more step:

```
apk add --allow-untrusted ./ddimension-feed.apk
apk update
apk add ddimension-feed          # turns the file install into a normal one
```

A package installed from a file is recorded in `/etc/apk/world` pinned to that
file's checksum (`ddimension-feed><Q1…>`), and a plain `apk upgrade` never
upgrades a pinned package; the last line replaces the pin with the plain name.

It installs two files, neither of them a conffile:

| | |
|---|---|
| `/etc/apk/keys/ddimension.pem` | the public half the indexes are signed with |
| `/etc/apk/repositories.d/ddimension.list` | the tree for this channel, release and architecture |

Not conffiles on purpose — a feed address that an update cannot correct is the
problem the package exists to avoid. To follow another feed as well, add a
second file in `/etc/apk/repositories.d`; apk reads all of them. Do not edit
this one, it is replaced on upgrade.

The package is built per channel, release and architecture, because the URL it
installs names all three. After upgrading a device to a new OpenWrt release,
install it again the same way from that release's tree — the old `.list` keeps
pointing at the old tree, which `apk update` says out loud rather than hiding.

The device images CI builds (below) contain `ddimension-feed` already and
follow the stable channel from the first boot.

<details>
<summary>By hand, without the package</summary>

```
wget -O /etc/apk/keys/ddimension.pem https://ddimension.github.io/openwrt-repo/keys/ddimension.pem
echo "https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_cortex-a53/packages.adb" \
  > /etc/apk/repositories.d/ddimension.list
apk update
apk add wwand luci-app-wwand
```

Pick the `<channel>/<release>/<arch>` matching the device. Done this way the
address is a fact about that one device and nothing keeps it current.
</details>

### Switch a device to the other channel

```
apk del ddimension-feed
apk --allow-untrusted \
  -X https://ddimension.github.io/openwrt-repo/main/<release>/<arch>/packages.adb \
  add ddimension-feed
apk update && apk upgrade
```

Both channels version their packages alike, so the switch is a reinstall from
the other tree. Back from `main` to `stable` works the same way with
`stable/`, followed by `apk upgrade --available` instead of `apk upgrade`: a
plain upgrade keeps the newer versions from main. `--available` acts on the
whole system — every package is set to what the configured repositories
offer, including packages from other feeds.

### Migrate a device set up before the channels

Two things change once for a device that followed this feed before the
channels existed:

- Up to `ddimension-feed` r2 the documented install was from a downloaded
  file, so the package is pinned and the device points at
  `<release>/<arch>/`. That path keeps working — it mirrors stable — but a
  pinned package never picks up a new `ddimension-feed`.
- `wwand` and its LuCI packages moved from date versions to release numbers
  ([Versions](#versions)); apk regards that as a downgrade and keeps the old
  ones. It is one only in number: 1.6.6 is exactly the code of the last date
  versions (r73 / r34 / r17).

One command settles both:

```
apk update && apk add -u ddimension-feed && apk update && apk upgrade --available
```

`apk add -u ddimension-feed` lifts the pin and upgrades to the current package
from the mirror, whose `.list` names `stable/<release>/<arch>/` (without `-u`
apk would keep the installed version); the second `apk update` reads that
tree; `apk upgrade --available` moves every package to what the repositories
offer, for wwand the release version. That is system-wide: base packages and
kmods move to whatever the distribution feeds offer too, which OpenWrt
otherwise advises against doing wholesale. To touch only this feed's
packages, name them: `apk upgrade --available wwand wwand-qmi luci-app-wwand
luci-proto-wwand` plus any other installed `wwand-*`. For a fleet, run the
same over ssh; `scripts/backup-ap-configs.sh <dir> -l -b <broker>` lists the
APs known to the MQTT broker. A device whose `.list` was written by hand needs `stable/` inserted
into the URL, or the package installed as above.

### Flash a firmware image

CI builds **ready-to-flash firmware images** with the wwand stack and
`ddimension-feed` baked in: all backends, eSIM and LuCI in the full builds
([`.github/ci/config.wwand`](.github/ci/config.wwand)), the QMI backend, eSIM
and LuCI in the ImageBuilder legs (`PKGS` in
[`build-imagebuilder.sh`](.github/ci/build-imagebuilder.sh)). `uqmi` is left out on purpose (config.wwand says why). Images
are **always built against the stable channel** of this feed, for the OpenWrt
master and stable base each, by
[build-device-images.yml](.github/workflows/build-device-images.yml):

| Device | OpenWrt `master` | OpenWrt `stable` | How |
|---|---|---|---|
| MikroTik Chateau 5G R17 ax | fork branch `chateau-ci` | fork branch `chateau-stable-backport` | full buildroot (device only exists in a PR) |
| ZyXEL NBG7815 | fork branch `nbg7815-update` | — | full buildroot (PR branch) |
| Zyxel NR7101 | `snapshot` | latest `25.12.x` | ImageBuilder |
| Zyxel LTE3301-PLUS | `snapshot` | latest `25.12.x` | ImageBuilder |

`master`/`stable` in this table is the **OpenWrt base**, not the feed
channel. The fork branches live in
[ddimension/openwrt](https://github.com/ddimension/openwrt): `chateau-ci` is
openwrt main plus the device support (#24335), the QCA8081 TX-clock fix
(#24566) and the ath11k reboot fix (#24601); `chateau-stable-backport` is
openwrt-25.12 plus the device PR.

Every run builds against **one** stable commit: the one of the feed run that
triggered it, or, started by hand, the tip of stable at that moment. Full
builds add this feed as `src-git` pinned to it (`…openwrt-repo.git^<sha>`);
the ImageBuilder legs pull the packages **signed** from
`stable/<release>/mipsel_24kc/` on gh-pages, after waiting until that tree
carries the `.published` stamp of that commit; the published images are
stamped with it.

**Triggers:** automatically after every successful feed run on `stable`
(i.e. after every release), and manually via
`gh workflow run build-device-images.yml -R ddimension/openwrt-repo --ref main`.
`-f testing_kernel=true` builds only the master full builds, with
`KERNEL_TESTING_PATCHVER`; the stable and ImageBuilder legs are skipped, and
the images stay run artifacts.

**Where the images live:**

- permanently on gh-pages:
  `https://ddimension.github.io/openwrt-repo/images/<group>/<base>/` —
  `<group>` is `chateau`, `nbg7815` or `zyxel`, `<base>` is `master` or
  `stable`. Flat: the images, `.manifest` (full package list, so you can
  verify the stack), `sha256sums`, `.published`. Each run replaces the
  directories it built; a leg that produced no sysupgrade image keeps the
  previous one.
- as GitHub Actions run artifacts `images-<group>-<base>` (retention 30 days);
  those of the full builds also contain the per-image package repository:

  ```
  gh run download -R ddimension/openwrt-repo \
    $(gh run list -R ddimension/openwrt-repo -w build-device-images -L1 --json databaseId -q '.[0].databaseId') \
    -n images-zyxel-stable
  ```

  An artifact holds one directory: `<target>-<subtarget>/` for full builds,
  `ramips-mt7621-<base>/` for the ImageBuilder.

### Build against this feed

Add to `feeds.conf` (or `feeds.conf.default`) of an OpenWrt buildroot or SDK:

```
src-git wwand https://github.com/ddimension/openwrt-repo.git;stable
```

`;stable` follows releases, `;main` development, and `^<commit>` pins one
commit. Then:

```
./scripts/feeds update wwand
./scripts/feeds install -a -p wwand
```

The LuCI packages build with plain `package.mk` (deliberately not
`luci.mk`, which can't install from a git `PKG_SOURCE`); at runtime they
depend on `luci-base` from the standard `luci` feed.

### Test builds locally (before burning CI)

Big builds should be validated locally first — same official `openwrt/sdk`
Docker containers, same checks as the workflow:

```
scripts/local-build.sh                            # full matrix (all releases × archs)
ARCHS=aarch64_cortex-a53 scripts/local-build.sh   # one arch
RELEASES=snapshot ARCHS=x86_64 PACKAGES="wwand" NPROC=4 scripts/local-build.sh
```

`PACKAGES` defaults to [`.github/ci/packages`](.github/ci/packages), the list
CI builds. `DDIMENSION_FEED_CHANNEL=main` builds `ddimension-feed` for the
main channel (default: stable).

Prints `PASS:`/`FAIL:` per package and `COMBO PASS/FAIL` per release×arch;
on failure the exact compiler errors land in
`/tmp/openwrt-repo-local-build/<release>-<arch>/vbuild-<pkg>.log` (override
with `LOGDIR=`). Iterating is cheap: the SDK volume of a failed combo is
kept, so a fix only rebuilds the failed package; volumes of passing combos
are deleted automatically. A kept volume does not notice changed environment
knobs such as `DDIMENSION_FEED_CHANNEL` — remove it
(`docker volume rm sdk-<release>-<arch>`) to build from scratch.

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

### Build device images locally

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
- `--feed SRC` — the wwand feed as src-git source; default
  `https://github.com/ddimension/openwrt-repo.git;stable` like CI,
  `…;main` builds against development, `…^<sha>` against one commit.
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

### Back up the fleet's configuration

`scripts/backup-ap-configs.sh` fetches the sysupgrade config archive — the
one LuCI offers as "Generate archive" — from every AP over ssh:

```
scripts/backup-ap-configs.sh <target-dir> [ap ...]

scripts/backup-ap-configs.sh /srv/backup -b mqtt.example.net  # whole fleet
scripts/backup-ap-configs.sh /srv/backup ap-attic ap-outdoor  # named APs
scripts/backup-ap-configs.sh /srv/backup -f aps.txt -d .lan   # from a file
```

Name no AP and the list comes from the MQTT broker: apman publishes
`properties/system/board` retained per AP, so subscribing to that pattern
enumerates the fleet with no list to maintain (`-b`, or `APMAN_BROKER`;
`APMAN_MQTT_OPTS` carries broker credentials). `-l` prints the list without
fetching anything.

The archive is pulled with `sysupgrade -b -`, which streams to stdout and
suppresses its own status output, so nothing is written on the AP — this
works on a full flash too. Each archive has to be valid gzip, valid tar and
contain `etc/config/` before it is kept, so a truncated transfer cannot pass
as a backup. Files land as `backup-<ap>-<timestamp>.tar.gz`; a failing AP
does not stop the others, and the exit status is non-zero if any failed.

## Repo handling

Rules for sessions that change packages here: [CLAUDE.md](CLAUDE.md). CI,
runners and the gh-pages publisher: [.github/ci/README.md](.github/ci/README.md).

### Branches and channels

Two branches, and each one is a channel of the binary feed:

| Branch | Channel | Published under | For |
|---|---|---|---|
| `main` | development | `…/main/<release>/<arch>/` | every change as soon as it is merged |
| `stable` | releases | `…/stable/<release>/<arch>/` and the pre-channel `…/<release>/<arch>/` | devices, and the device images |

Work happens on `main`. A release moves `stable` forward to a commit of `main`
and tags it:

```
scripts/release-stable.sh             # stable -> origin/main, tag YYYY.MM.DD
scripts/release-stable.sh <commit>    # release an older state of main
```

The script only ever fast-forwards `stable`, lists the commits and the package
versions that change, and pushes branch and tag in one atomic push after
asking. It refuses a ref that is not on `origin/main` (built there first),
and while any package carries a development version (see
[Versions](#versions)). That push starts the stable feed build; its success
starts the device images. A release that changes only `.md` files starts no
build — `gh workflow run build.yml -R ddimension/openwrt-repo --ref stable`.

`stable` never moves backwards. A GitHub ruleset refuses force-pushes and
deletion: every src-git checkout of this feed updates with `git pull
--ff-only`, and every installed device follows stable. A fix that cannot wait
for `main` goes onto `stable` directly, and then back:

```
git switch -c hotfix origin/stable     # fix, commit
git push origin HEAD:stable            # builds and publishes stable
git tag -a YYYY.MM.DD -m "…" && git push origin YYYY.MM.DD   # .2 if that day has one
git switch main && git merge origin/stable && git push
```

Until `origin/stable` is merged back, `release-stable.sh` refuses to release,
because stable would lose the fix.

Each channel publishes with the CI scripts of its own branch, so a change to
the publishing (`.github/ci/publish-pages.sh`, the site layout) reaches the
stable side with the next release. The device-image workflow always runs from
`main` (GitHub runs `workflow_run` workflows from the default branch), so a
change there takes effect at once — still against stable packages.

### Versions

`wwand`, `luci-app-wwand` and `luci-proto-wwand` carry the version of the
wwand release they belong to; the three source repositories are tagged
`vX.Y.Z` together. [`scripts/bump-source.sh`](scripts/bump-source.sh) derives
the package version from the pinned commit with `git describe`:

| Pinned commit | Package version | Channel |
|---|---|---|
| tag `v1.6.6` | `1.6.6-r1` | stable |
| 3 commits after `v1.6.6` | `1.6.6_p3-r1` | main |

apk orders `1.6.6` < `1.6.6_p3` < `1.6.7`, so both channels upgrade normally,
and no build date is part of a version. `-rN` is OpenWrt's packaging revision:
back to 1 with every new version, counted up by hand for packaging-only
changes.

Until r73 / r34 / r17 these packages had no version of their own, and OpenWrt
derived one from date and commit (`2026.09.11~c27f72e6`). apk sorts that above
every real version number, so moving to release numbers is a downgrade in
apk's eyes — once, and only in number: 1.6.6 is the r73 / r34 / r17 code. See
[Migrate a device set up before the channels](#migrate-a-device-set-up-before-the-channels).

### Updating a package to a newer source commit

Changes go to `main`; stable gets them with the next release.

For `wwand`, `luci-app-wwand` and `luci-proto-wwand` there is one command:

```
scripts/bump-source.sh wwand main         # development: e.g. 1.6.6_p3
scripts/bump-source.sh wwand v1.6.7       # a release:   1.6.7
```

It pins the commit, sets `PKG_VERSION` from `git describe`
([Versions](#versions)), resets `PKG_RELEASE` to 1, and runs
`scripts/update-hashes.sh` — restoring the Makefile if that fails; commit the
Makefile. It refuses the same version for a different commit (the tarball
name would be reused) and a lower version than the current one (`--force`). A release of the stack: tag
`vX.Y.Z` in the wwand, luci-app-wwand and luci-proto-wwand repositories, pin
the three tags, commit, `scripts/release-stable.sh`.

The other git-source packages (upstreams with their own or no version scheme)
are pinned via `PKG_SOURCE_VERSION` by hand. `apman` has its own release script
([apman/README.md](apman/README.md)). To ship a new version:

1. bump `PKG_SOURCE_VERSION` (and `PKG_VERSION` or `PKG_SOURCE_DATE`, as the
   package uses them) in the package's Makefile and increment `PKG_RELEASE`,
2. run **`scripts/update-hashes.sh <package>`** — it computes the matching
   `PKG_MIRROR_HASH` in the official SDK container (the only authoritative
   source; host-side tar/zstd replication has produced wrong values) and
   writes it into the Makefile,
3. commit both changes together on `main` — CI builds and publishes it to the
   main channel,
4. once it has proven itself there, release: `scripts/release-stable.sh`.

CI runs gh-action-sdk in **per-package mode** (`PACKAGES`), which builds
only the packages listed in [`.github/ci/packages`](.github/ci/packages) plus
their real dependencies and enforces the mirror hash. The hash check is a
no-op for the packages that build from `files/` in this repo and declare no
`PKG_SOURCE` (`ddimension-feed`, `homesync`, `wpad-ieee8021x` and the `q*`
packages). `homesync` needs `snapclient-mptcp` only at runtime
(`EXTRA_DEPENDS`); `snapcast-mptcp` is on the list itself, so its C++ tree is
compiled in CI. `heatingrod`, `pcie_mhi` and `python3-edlclient` are not on
the list: a change to them is only as tested as your local build.

### Publishing

CI ([build.yml](.github/workflows/build.yml)) builds the feed on every push to
`main` or `stable` and publishes the trees of that channel to GitHub Pages;
stable also rewrites the pre-channel mirror. Currently built releases:
**`snapshot`** (master) and **`openwrt-25.12`** (openwrt-24.10 is no longer
built). Further OpenWrt release branches are added to the `release:` matrix in
the workflow and show up under the same URL scheme. A release dropped from the
matrix keeps its trees until they are removed explicitly
(`publish-pages.sh --remove`, see [.github/ci/README.md](.github/ci/README.md)).

Every published tree carries a `.published` stamp — UTC publish time, channel,
source commit and Actions run id — which also supplies the dates in the
directory indexes:

```
$ curl -s https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/x86_64/.published
<UTC time> stable <commit sha> <run id>
```

### Signing

Both signing keys are configured; the public halves live under
[`keys/`](keys/) and are published at the site root.

- **apk** (snapshot, 25.12+): ECDSA key (`keys/ddimension.pem`), private
  half in the `PRIVATE_KEY` repo secret. Both channels are signed with it.
  On a device it is `/etc/apk/keys/ddimension.pem` (any unique name — do NOT
  overwrite the stock `public-key.pem`); `ddimension-feed` installs it, and so
  it is in every image CI builds. Regenerate with
  `openssl ecparam -name prime256v1 -genkey -noout -out private-key.pem`.
- **opkg** (usign key `keys/93f8441660b57edd.pub`, filename = key
  fingerprint, private half in the `KEY_BUILD` repo secret): kept for
  opkg-based releases; currently unused since openwrt-24.10 was dropped
  from the build matrix.

### Licensing

The packaging in this repo (Makefiles, scripts) is GPL-2.0-only (see
[LICENSE](LICENSE)). Each package declares its own license via
`PKG_LICENSE` (verified against the upstream license files and source
headers). Of note: `qfirehose` and `qlog` are Quectel vendor code — their
NOTICE files permit use/redistribution **for Quectel customers**
(qfirehose: binary redistribution only); they are not open source in the
OSI sense.
