# openwrt-repo

OpenWrt **package feed** for the [wwand](https://github.com/ddimension/wwand)
cellular connection manager and the modem tooling around it — signed binary
repositories for eight architectures on
[ddimension.github.io/openwrt-repo](https://ddimension.github.io/openwrt-repo/),
in two channels: **stable** (releases) and **main** (development). This repo
carries the OpenWrt package definitions; most sources live in their own
repositories, pinned to a commit.

Our other packages — AP management (`apman`), multiroom audio
(`snapcast-mptcp`, `homesync`), the `wpad` variants, `nsca-ng`,
`usb-relay-hid`, the Lua bindings and `heatingrod` — live in
[ddimension/openwrt-addon-feed](https://github.com/ddimension/openwrt-addon-feed)
since 2026-10-04 and are published at
[ddimension.github.io/openwrt-addon-feed](https://ddimension.github.io/openwrt-addon-feed/).
Both feeds are independent and signed with the same key; `ddimension-feed`
installs a `.list` for each. One package here reaches across: `wwand-apntest`
reports its results with `send_nsca`, which is `nsca-ng` — in the add-on feed.
A box that runs APN tests therefore needs both feeds, which r4 of
`ddimension-feed` sets up by itself.

One order has to be kept while the add-on feed is young: r4 points at
`…/openwrt-addon-feed/<channel>/<release>/<arch>/`, so **that tree must exist
before r4 reaches a device**, or `apk update` reports a 404 for it. The add-on
feed publishes its stable channel only from a release tag, so a release of
this feed that carries r4 comes *after* the add-on feed's first release. On
the main channel it is enough that the add-on feed has built main once. The split exists for build time: a one-line change
in `wwand` used to rebuild boost, hostapd and collectd too, because the feed
build throws its SDK tree away on every run.

## Packages

| Package | What it is | Binary packages | Source | CI |
|---|---|---|---|---|
| `wwand` | event-driven cellular connection manager (QMI, MBIM, NCM, PCIe/MHI), eSIM, scheduled APN tests | `wwand`, `wwand-qmi`, `wwand-mbim`, `wwand-ncm`, `wwand-mhi`, `wwand-esim`, `wwand-gps`, `wwand-apntest`, `wwand-datapath-rmnet_nss`, `wwand-datapath-rmnet_nss_mhi` | [ddimension/wwand](https://github.com/ddimension/wwand) | ✓ |
| `luci-app-wwand` | LuCI modem status page, modem editor, live settings; the signal/statistics graphs as a separate package | `luci-app-wwand`, `luci-app-wwand-statistics` | [ddimension/luci-app-wwand](https://github.com/ddimension/luci-app-wwand) | ✓ |
| `luci-proto-wwand` | LuCI protocol handler for `proto wwand` interfaces | same | [ddimension/luci-proto-wwand](https://github.com/ddimension/luci-proto-wwand) | ✓ |
| `wwand-lpac` | lpac for eSIM profile management, static wolfSSL/curl | same | upstream [estkme-group/lpac](https://github.com/estkme-group/lpac) | ✓ |
| `wwand-qlog` | on-demand Qualcomm diag (QMDL) capture through Quectel QLog: `wwandctl qlog`. A wwand plugin, kept out of the wwand sources on purpose — wwand only resolves and publishes the modem's diag node and never opens it | same | [ddimension/wwand-qlog](https://github.com/ddimension/wwand-qlog) | ✓ |
| `wwand-ipa` | eSIM fleet management: the router as the SGP.32 IoT Profile Assistant of an eIM, as a wwand plugin, plus its LuCI page | `wwand-ipa`, `luci-app-wwand-ipa` | [ddimension/wwand-ipa](https://github.com/ddimension/wwand-ipa) | ✓ |
| `wwand-ipad` | the assistant `wwand-ipa` drives: ipad, an SGP.32 v1.3 IPA (IoT eUICC, or an SGP.22 card through an emulation signed with a device key) that reaches the card through lpac's stdio APDU protocol so wwand relays it over the modem's own channel; mbedTLS linked in statically | same | [ddimension/ipad](https://github.com/ddimension/ipad) | ✓ |
| `wwand-rsim` | remote SIM for wwand (QMI UIM Remote): a modem runs on a card that is not in its own slot — in a reader on the router or on a SIM host over SSH (Smartmouse/Phoenix, PC/SC), in a phone over Bluetooth SAP, in a modem wwand does not manage (AT+CSIM), in another modem of the router (SIM sponsor), in a modem of another wwand router, or in an osmo-remsim SIM bank (RSPRO); `wwandctl rsim` and a LuCI page. `rsim-card` is the card-side helper alone, for a SIM host; `wwand-rsim-provider` lets this router's modem cards be borrowed by other routers | `wwand-rsim`, `wwand-rsim-provider`, `rsim-card`, `rsim-card-pcsc`, `luci-app-wwand-rsim` | [ddimension/wwand-rsim](https://github.com/ddimension/wwand-rsim) | ✓ |
| `ddimension-feed` | both feeds' addresses and the signing key, see [Set up a device](#set-up-a-device) | same | local (`files/`) | ✓ |
| `qfirehose` | Quectel QFirehose V1.4.21, firmware flasher | same | bundled source zip | ✓ |
| `qflash` | Quectel QFlash 2.0, legacy firmware flasher | same | bundled source tarball | ✓ |
| `qlog` | Quectel QLog V1.5.8, diagnostic log capture with Quectel's filter profiles | same | bundled source zip | ✓ |
| `pcie_mhi` | Quectel PCIe MHI 1.6.0, with ordinary and NSS variants ([pcie_mhi/README.md](pcie_mhi/README.md)) | `kmod-pcie_mhi`, `kmod-pcie_mhi_nss` | bundled source | — |
| `rmnet-nss` | Vendor QMAP interfaces through Qualcomm NSS ([rmnet-nss/README.md](rmnet-nss/README.md)) | `kmod-rmnet-nss` | bundled QSDK-derived source | — |
| `python3-edlclient` | Qualcomm EDL/DIAG toolkit, scoped to `qc_diag` | same | upstream [bkerler/edl](https://github.com/bkerler/edl) | — |

**CI**: ✓ = built and published for every architecture; the list is
[`.github/ci/packages`](.github/ci/packages). — = in the feed, deliberately not
built by CI: the MHI and NSS driver packages require local builds and hardware
tests. `python3-edlclient` is built on demand. Build these in a compatible buildroot.

## Binary package repositories

```
https://ddimension.github.io/openwrt-repo/<channel>/<release>/<arch>/
```

`<channel>` is `stable` or `main`, `<release>` the OpenWrt release
(`openwrt-25.12`, or `snapshot` for master). Per tree: **apk** is
`ddimension-feed.apk`, the feed's address and key for exactly that tree (see
[Set up a device](#set-up-a-device)); **tree** is the repository itself, browsable.

Each tree keeps the **last 10 versions** of every package — the index lists them
all, so a device can go back (see [Go back to an older package
version](#go-back-to-an-older-package-version)). `versions.json` in the tree
says per file which version it is, when it was built and when it was first
published; the pre-channel mirror keeps the newest version only.

Beyond that window, every release is archived on its
[GitHub release](https://github.com/ddimension/openwrt-repo/releases): one
`<release>-<arch>.zip` per package tree (all `.apk`, the signed `packages.adb`,
`index.json`), the loose `ddimension-feed-<release>-<arch>.apk`, the static
`rsim-card`, and the device images built against that release. Those assets do
not count against the 1 GB a Pages site may have, and they stay. They are an
archive, not a repository: the assets of a tag share one flat namespace, so the
same package file name of eight architectures would collide, and apk resolves
package files relative to its index — a device installs from the feed above.

| Arch | Covers (among others) | stable · 25.12 | stable · snapshot | main · 25.12 | main · snapshot |
|---|---|---|---|---|---|
| `aarch64_cortex-a53` | qualcommax (MikroTik Chateau, ipq807x, ipq60xx), mediatek/filogic | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_cortex-a53/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_cortex-a53/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_cortex-a53/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_cortex-a53/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_cortex-a53/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_cortex-a53/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_cortex-a53/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_cortex-a53/) |
| `aarch64_cortex-a72` | bcm27xx/bcm2711 (Raspberry Pi 4) | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_cortex-a72/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_cortex-a72/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_cortex-a72/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_cortex-a72/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_cortex-a72/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_cortex-a72/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_cortex-a72/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_cortex-a72/) |
| `aarch64_generic` | rockchip/armv8 (RK33xx/RK35xx: Hinlink, NanoPi, Radxa) | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_generic/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/aarch64_generic/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_generic/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/aarch64_generic/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_generic/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/aarch64_generic/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_generic/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/aarch64_generic/) |
| `arm_cortex-a15_neon-vfpv4` | ipq806x | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/arm_cortex-a15_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/arm_cortex-a15_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/arm_cortex-a15_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/arm_cortex-a15_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/arm_cortex-a15_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/arm_cortex-a15_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/arm_cortex-a15_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/arm_cortex-a15_neon-vfpv4/) |
| `arm_cortex-a7_neon-vfpv4` | ipq40xx | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/arm_cortex-a7_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/arm_cortex-a7_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/arm_cortex-a7_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/arm_cortex-a7_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/arm_cortex-a7_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/arm_cortex-a7_neon-vfpv4/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/arm_cortex-a7_neon-vfpv4/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/arm_cortex-a7_neon-vfpv4/) |
| `mips_24kc` | ath79 (Ubiquiti) | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/mips_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/mips_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/mips_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/mips_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/mips_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/mips_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/mips_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/mips_24kc/) |
| `mipsel_24kc` | ramips/mt7621 (Zyxel NR7101, LTE3301-PLUS), ramips/mt7620 (LTE3301-M209/Q222) | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/mipsel_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/mipsel_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/mipsel_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/mipsel_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/mipsel_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/mipsel_24kc/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/mipsel_24kc/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/mipsel_24kc/) |
| `x86_64` | x86/64 (VMs, APU, router PCs) | [apk](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/x86_64/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/x86_64/) | [apk](https://ddimension.github.io/openwrt-repo/stable/snapshot/x86_64/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/stable/snapshot/x86_64/) | [apk](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/x86_64/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/openwrt-25.12/x86_64/) | [apk](https://ddimension.github.io/openwrt-repo/main/snapshot/x86_64/ddimension-feed.apk) · [tree](https://ddimension.github.io/openwrt-repo/main/snapshot/x86_64/) |

The [start page](https://ddimension.github.io/openwrt-repo/) shows the same
table, generated from what is actually published. The **pre-channel path**
`…/<release>/<arch>/` stays valid: a copy of `stable/<release>/<arch>/`,
rewritten by every stable publish, so devices set up before the channels
existed keep working. Device images live under
[`images/`](https://ddimension.github.io/openwrt-repo/images/), signing keys
under [`keys/`](https://ddimension.github.io/openwrt-repo/keys/).

**Host tools** under
[`tools/<channel>/<arch>/`](https://ddimension.github.io/openwrt-repo/tools/):
programs that do not run on the router but next to it. Today that is
`rsim-card` for a **SIM host** — the machine whose reader holds the card when a
modem uses `option rsim_reader ssh:<user>@<host>:<reader>`. wwand runs it there
*by name*, so it belongs in that machine's `PATH`, and CI links it statically
so nothing has to be installed:

```sh
curl -O https://ddimension.github.io/openwrt-repo/tools/stable/x86_64/rsim-card
install -m755 rsim-card /usr/local/bin/rsim-card
```

## How-tos

### Set up a device

The feeds' addresses and key are themselves a package, `ddimension-feed`.
Install it once, **by name**, from the tree matching the channel, the
installed release and the architecture, and the device follows **both** feeds
from then on — this one and the add-on feed — including any later change to an
address or to the key, which arrives as an ordinary upgrade rather than as a
note somebody has to act on.

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

It installs three files, none of them a conffile:

| | |
|---|---|
| `/etc/apk/keys/ddimension.pem` | the public half both feeds' indexes are signed with |
| `/etc/apk/repositories.d/ddimension.list` | this feed's tree for the channel, release and architecture |
| `/etc/apk/repositories.d/ddimension-addon.list` | the add-on feed's tree, same channel, release and architecture |

Not conffiles on purpose — a feed address that an update cannot correct is the
problem the package exists to avoid. To follow a further feed, add another file
in `/etc/apk/repositories.d`; apk reads all of them. Do not edit ours, they are
replaced on upgrade. (Up to r3 there was only the first `.list`; r4 added the
second when the add-on packages moved to their own repository.)

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
# only if the device also needs add-on packages (apman, snapclient-mptcp, wpad-*, …)
echo "https://ddimension.github.io/openwrt-addon-feed/stable/snapshot/aarch64_cortex-a53/packages.adb" \
  > /etc/apk/repositories.d/ddimension-addon.list
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

### Go back to an older package version

Every tree keeps the **last 10 versions** of each package, so a bad version can
be undone on the spot:

```
apk list wwand                      # what the tree offers
apk add wwand=1.6.9-r1              # go back to that one
```

apk reports `Downgrading` and writes the pin `wwand=1.6.9-r1` into
`/etc/apk/world`; `apk upgrade`, `apk upgrade --available` included, leaves a
pinned package alone. Lift the pin when the next good version is out:

```
apk add wwand                       # floating again
apk upgrade
```

Which versions a tree has, with their build and publish dates, is in its
`versions.json` (and in the directory listing). The pre-channel path
`…/<release>/<arch>/` keeps only the newest — downgrades need `stable/…` or
`main/…`.

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
[`build-imagebuilder.sh`](.github/ci/build-imagebuilder.sh)). `uqmi` is left out on purpose (config.wwand says why).
A single device can add to that: `.github/ci/config.<slug>` is appended for that
full-build leg only — today [`config.chateau`](.github/ci/config.chateau), which
gives the MikroTik image `kmod-usb-serial-ftdi` so an FTDI cable shows up as
`/dev/ttyUSB*` without installing anything. Images
are **always built against the stable channel** of this feed, for the OpenWrt
master and stable base each, by
[build-device-images.yml](.github/workflows/build-device-images.yml):

| Device | OpenWrt `master` | OpenWrt `stable` | How |
|---|---|---|---|
| MikroTik Chateau 5G R17 ax | fork branch `chateau-ci` | fork branch `chateau-stable-backport` | full buildroot (device only exists in a PR) |
| ZyXEL NBG7815 | fork branch `nbg7815-update` | — | full buildroot (PR branch) |
| Zyxel NR7101 | upstream `main` + our patch | upstream `openwrt-25.12` + our patch | full buildroot (the patch changes the DTS, so a kernel has to be built) |
| Zyxel LTE3301-M209/Q222 | fork branch `lte3301` | — | full buildroot (the devices do not exist upstream: DTS, mt7620 image recipes, U-Boot and jboot-tools patches) |
| Zyxel LTE3301-PLUS | `snapshot` | latest `25.12.x` | ImageBuilder |

`master`/`stable` in this table is the **OpenWrt base**, not the feed
channel. The fork branches live in
[ddimension/openwrt](https://github.com/ddimension/openwrt): `chateau-ci` is
openwrt main plus the device support (#24335), the QCA8081 TX-clock fix
(#24566) and the ath11k reboot fix (#24601); `chateau-stable-backport` is
openwrt-25.12 plus the device PR.

The NR7101 needs no fork branch: it builds from upstream (`main` for the master
base, `openwrt-25.12` for stable) and the one change it carries is applied at
build time from [`nr7101-lte-power.patch`](.github/ci/nr7101-lte-power.patch) —
the modem power line (GPIO 18) as an exported `gpio-export` line with the
default the DT hog used to set, plus the matching `gpio_switch`. Without it the
line is hogged by the kernel, invisible in `/sys/class/gpio`, and wwand can
only pulse the reset line instead of power-cycling the modem. Should the patch
stop applying after an upstream change, that leg fails loudly
(`build-images.sh`) — refresh the patch, it is not carried in a branch.

Every run builds against **one** stable commit: the one of the release whose
feed run triggered it, or, started by hand, the commit of the newest release
tag. Full
builds add this feed as `src-git` pinned to it (`…openwrt-repo.git^<sha>`);
the ImageBuilder legs pull the packages **signed** from
`stable/<release>/mipsel_24kc/` on gh-pages, after waiting until that tree
carries the `.published` stamp of that commit; the published images are
stamped with it.

**Triggers:** automatically after every successful feed run of a release tag,
and manually via
`gh workflow run build-device-images.yml -R ddimension/openwrt-repo --ref main`.
`-f testing_kernel=true` builds only the master full builds, with
`KERNEL_TESTING_PATCHVER`; the stable and ImageBuilder legs are skipped, and
the images stay run artifacts.

**Where the images live:**

- permanently on gh-pages:
  `https://ddimension.github.io/openwrt-repo/images/<group>/<base>/` —
  `<group>` is `chateau`, `nbg7815`, `nr7101`, `lte3301` or `zyxel`, `<base>` is `master` or
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
src-git ddaddon https://github.com/ddimension/openwrt-addon-feed.git;stable
```

The second line is only needed for add-on packages; the two feed **names** must
differ, or `scripts/feeds` decides which clone wins. `;stable` follows the
stable branch (releases plus any preparation not yet released), `;main`
development, and `^<commit>` pins one commit — the commit of a release tag for
exactly what devices get. Then:

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

Name no AP and the list comes from the MQTT broker: apman (add-on feed) publishes
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

Two long-lived branches, independent of each other, and each one is a channel
of the binary feed:

| Branch | Channel | Published under | Published by |
|---|---|---|---|
| `main` | development | `…/main/<release>/<arch>/` | every push to `main` |
| `stable` | releases | `…/stable/<release>/<arch>/` and the pre-channel `…/<release>/<arch>/` | a release tag `YYYY.MM.DD[.N]` on `stable` — a push to the `stable` branch only builds |

`stable` is not a pointer onto `main`. It takes from main what is ready and
leaves the rest, in any of these ways:

```
git switch -c take origin/stable && git cherry-pick -x <commit> && git push origin HEAD:stable
scripts/stable-take.sh <pkg>...      # those package directories, as on main
scripts/stable-take.sh --ci          # .github/ (workflows, CI scripts)
scripts/stable-take.sh --all         # merge main into stable
```

and a fix that belongs on stable first is made there (and merged up into
`main` afterwards). For the wwand stack the source repositories have the same
two lines: feed stable pins their `stable` branch, feed main their `main`
([Versions](#versions)).

Pushes to `stable` build and publish nothing, so a release can be prepared in
several steps. The release itself is a tag:

```
scripts/release-stable.sh             # tag the tip of stable YYYY.MM.DD
scripts/release-stable.sh <commit>    # an earlier commit of stable
```

It refuses a commit that is not on `origin/stable`, one without a successful
build run (`--no-ci-check` for a commit that built nothing), one already
released, and while any package carries a development version
(`X.Y.Z_pN`/`X.Y.Z_preN`; `--allow-dev` overrides). It lists the commits and
package versions since the previous release tag and pushes only the tag; that
build publishes stable, and its success starts the device images.

`stable` still never moves backwards: a GitHub ruleset refuses force-pushes and
deletion. Note for `src-git …;stable` users: that follows the stable BRANCH,
which may carry preparation that is not released yet; pin a release with
`^<commit of the tag>` for exactly what devices get.

Each channel builds with the CI scripts of its own commit — a change to the
publishing reaches stable with `scripts/stable-take.sh --ci`. The device-image
workflow always runs from `main` (GitHub runs `workflow_run` workflows from the
default branch), against the stable packages of the release that triggered it.

### Versions

`wwand`, `luci-app-wwand` and `luci-proto-wwand` have two lines in their
source repositories as well: releases `vX.Y.Z` are tagged on their `stable`
branch, and `main` carries a marker `vX.Y.0-dev` where the minor it develops
opened. [`scripts/bump-source.sh`](scripts/bump-source.sh) derives the package
version from the pinned commit and the channel (the checked-out feed branch,
or `--channel`):

| Pinned commit | Package version | Channel |
|---|---|---|
| tag `v1.6.10` on source stable | `1.6.10-r1` | stable (release) |
| 3 commits after `v1.6.10` on source stable | `1.6.10_p3-r1` | stable (not releasable) |
| 14 commits after `v1.7.0-dev` on source main | `1.7.0_pre14-r1` | main |

apk orders `1.6.10` < `1.6.10_p3` < `1.7.0_pre1` < `1.7.0_pre14` < `1.7.0`, so
main always sorts above every stable patch release, both channels upgrade
normally, and no build date is part of a version. The pinned commit must be on
the source branch of the same name. Opening a new minor: merge source main into
source stable, tag `vX.Y.0` there, put the next `vX.(Y+1).0-dev` on main.
`-rN` is OpenWrt's packaging revision: back to 1 with every new version,
counted up by hand for packaging-only changes. Other git-source packages (one
line, no source `stable` branch) keep `vX.Y.Z` → `X.Y.Z`, then `X.Y.Z_pN`.

Until r73 / r34 / r17 these packages had no version of their own, and OpenWrt
derived one from date and commit (`2026.09.11~c27f72e6`). apk sorts that above
every real version number, so moving to release numbers is a downgrade in
apk's eyes — once, and only in number: 1.6.6 is the r73 / r34 / r17 code. See
[Migrate a device set up before the channels](#migrate-a-device-set-up-before-the-channels).

### Updating a package to a newer source commit

Changes go to `main`; stable takes them when they are ready (above).

For `wwand`, `luci-app-wwand` and `luci-proto-wwand` there is one command, run
on the feed branch it is meant for:

```
scripts/bump-source.sh wwand main         # on feed main:   e.g. 1.7.0_pre3
scripts/bump-source.sh wwand v1.6.10      # on feed stable: 1.6.10
```

It pins the commit, sets `PKG_VERSION` from `git describe`
([Versions](#versions)), resets `PKG_RELEASE` to 1, and runs
`scripts/update-hashes.sh` — restoring the Makefile if that fails; commit the
Makefile. It refuses the same version for a different commit (the tarball
name would be reused), a commit that is not on the channel's source branch,
and a lower version than the current one (`--force`). A patch release of the
stack: tag `vX.Y.Z` on the source `stable` branch of each repository that
changed, pin the tags on feed stable, push (builds), `scripts/release-stable.sh`.

The other git-source packages (upstreams with their own or no version scheme)
are pinned via `PKG_SOURCE_VERSION` by hand. To ship a new version:

1. bump `PKG_SOURCE_VERSION` (and `PKG_VERSION` or `PKG_SOURCE_DATE`, as the
   package uses them) in the package's Makefile and increment `PKG_RELEASE`,
2. run **`scripts/update-hashes.sh <package>`** — it computes the matching
   `PKG_MIRROR_HASH` in the official SDK container (the only authoritative
   source; host-side tar/zstd replication has produced wrong values) and
   writes it into the Makefile,
3. commit both changes together on `main` — CI builds and publishes it to the
   main channel,
4. once it has proven itself there, take it onto stable
   (`scripts/stable-take.sh <package>`), and release with
   `scripts/release-stable.sh` when stable is ready.

CI runs gh-action-sdk in **per-package mode** (`PACKAGES`), which builds
only the packages listed in [`.github/ci/packages`](.github/ci/packages) plus
their real dependencies and enforces the mirror hash. The hash check is a
no-op for the packages that build from `files/` in this repo and declare no
`PKG_SOURCE` (`ddimension-feed` and the `q*` packages). `pcie_mhi` and
`python3-edlclient` are not on the list: a change to them is only as tested as
your local build. The add-on packages are not here at all any more — they are
built by [ddimension/openwrt-addon-feed](https://github.com/ddimension/openwrt-addon-feed).

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
