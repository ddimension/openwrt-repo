# openwrt-repo

OpenWrt **package feed** for the [wwand](https://github.com/ddimension/wwand)
cellular connection manager and a few companions. This repo carries only the
OpenWrt package definitions (Makefiles, patches, packaging files); most sources
live in their own repositories and are fetched via `PKG_SOURCE_URL`, pinned to
a commit.

## Branches and channels

Two branches, and each one is a channel of the binary feed:

| Branch | Channel | Published under | For |
|---|---|---|---|
| `main` | development | `…/main/<release>/<arch>/` | every change as soon as it is merged |
| `stable` | releases | `…/stable/<release>/<arch>/` | devices, and the device images |

Work happens on `main`. A release moves `stable` forward to a commit of `main`
and tags it:

```
scripts/release-stable.sh             # stable -> origin/main, tag YYYY.MM.DD
scripts/release-stable.sh <commit>    # release an older state of main
```

The script only ever fast-forwards `stable`, lists the commits and the package
versions that change, and pushes branch and tag in one atomic push after
asking. It refuses while `wwand`, `luci-app-wwand` or `luci-proto-wwand` carry
a development version (see [Versions](#versions)). That push starts the stable
feed build; its success starts the device images.

`stable` never moves backwards. A GitHub ruleset refuses force-pushes and
deletion: every src-git checkout of this feed updates with `git pull
--ff-only`, and every installed device follows stable. A fix that cannot wait
for `main` goes onto `stable` directly, and then back:

```
git switch -c hotfix origin/stable     # fix, commit
git push origin HEAD:stable            # builds and publishes stable
git tag -a YYYY.MM.DD -m "…" && git push origin YYYY.MM.DD
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
| tag `v1.6.5` | `1.6.5-r1` | stable |
| 7 commits after `v1.6.5` | `1.6.5_p7-r1` | main |

apk orders `1.6.5` < `1.6.5_p7` < `1.6.6`, so both channels upgrade normally,
and no build date is part of a version. `-rN` is OpenWrt's packaging revision:
back to 1 with every new version, counted up for packaging-only changes.

Until r73 / r34 / r17 these packages had no version of their own, and OpenWrt
derived one from date and commit (`2026.09.11~c27f72e6`). apk sorts that above
every real version number, so moving to release numbers is a downgrade in
apk's eyes — once, see
[Migrating](#migrating-devices-set-up-before-the-channels).

## Packages

| Package | Source | CI |
|---|---|---|
| `wwand` (binary packages `wwand`, `wwand-qmi`, `wwand-mbim`, `wwand-ncm`, `wwand-mhi`, `wwand-esim`, `wwand-apntest`, `wwand-datapath-rmnet_nss`, `wwand-datapath-rmnet_nss_mhi`) | https://github.com/ddimension/wwand | ✓ |
| `luci-app-wwand` | https://github.com/ddimension/luci-app-wwand | ✓ |
| `luci-proto-wwand` | https://github.com/ddimension/luci-proto-wwand | ✓ |
| `wwand-lpac` | upstream [estkme-group/lpac](https://github.com/estkme-group/lpac) (bundled static wolfSSL/curl) | ✓ |
| `apman` | [ddimension/apman-agent](https://github.com/ddimension/apman-agent) — AP manager: ubus↔MQTT bridge, collectd plugin, on-AP RADIUS server ([apman/README.md](apman/README.md)) | ✓ |
| `libubus-lua-async` | upstream [ubus](https://git.openwrt.org/project/ubus.git) — the stock Lua binding plus `conn:call_async()` | via `apman` |
| `ddimension-feed` | local (`files/`) — this feed's address and signing key, see [On the device](#on-the-device) | ✓ |
| `homesync` | local (`files/`) — synchronised multiroom speaker: UCI front end for `snapclient-mptcp` | ✓ |
| `snapcast-mptcp` (binary packages `snapserver-mptcp`, `snapclient-mptcp`) | [ddimension/snapcast](https://github.com/ddimension/snapcast) — Snapcast, MPTCP variant | ✓ |
| `luacurl` | upstream [Lua-cURL/Lua-cURLv3](https://github.com/Lua-cURL/Lua-cURLv3) | ✓ |
| `lua-mosquitto` | upstream [flukso/lua-mosquitto](https://github.com/flukso/lua-mosquitto) | ✓ |
| `qfirehose` | bundled Quectel QFirehose V1.4.21 source zip (firmware flasher) | ✓ |
| `qflash` | bundled Quectel QFlash 2.0 source tarball (legacy firmware flasher) | ✓ |
| `qlog` | bundled Quectel QLog V1.5.8 source zip (diagnostic log capture, with Quectel's filter profiles) | ✓ |
| `usb-relay-hid` | upstream [OzFalcon/usb-relay-hid](https://github.com/OzFalcon/usb-relay-hid) | ✓ |
| `wpad-ieee8021x` | local (`files/`) — `ieee8021x` netifd protocol: wired 802.1X through wpa_supplicant's ubus interface | ✓ |
| `wpad-saeradh2e` | OpenWrt's `hostapd` package (full/OpenSSL wpad only) plus our SAE-over-RADIUS patches; the patches also live in [ddimension/hostapd](https://github.com/ddimension/hostapd) branch `sae-radius-h2e` | ✓ |
| `heatingrod` | bundled snapshot of the heatingrod Rust workspace — PV-surplus heating rod controller ([heatingrod/README.md](heatingrod/README.md)) | — |
| `pcie_mhi` | bundled Quectel PCIe/MHI host driver V1.3.8, ported to kernel 6.18 ([pcie_mhi/README.md](pcie_mhi/README.md)) | — |
| `python3-edlclient` | upstream [bkerler/edl](https://github.com/bkerler/edl) — Qualcomm EDL/DIAG toolkit, scoped to `qc_diag` | — |

**CI**: ✓ = built and published by CI; the list is
[`.github/ci/packages`](.github/ci/packages). `libubus-lua-async` is not on it
but is built as a dependency of `apman`. — = in the feed, deliberately not
built by CI: `heatingrod` builds rust/host from source (~35–45 GB build dir),
`pcie_mhi` does not get the RG650E past the MHI M0 handshake yet, and
`python3-edlclient` is built on demand. Build those locally or in a buildroot.

## Binary package repositories

CI ([build.yml](.github/workflows/build.yml)) builds the feed on every push to
`main` or `stable` and publishes per-channel, per-release, per-architecture
binary repositories to GitHub Pages:

```
https://ddimension.github.io/openwrt-repo/<channel>/<release>/<arch>/
```

- `<channel>`: `stable` or `main` (see [Branches and channels](#branches-and-channels))
- `<release>`: the OpenWrt release — `snapshot` (master) or `openwrt-25.12`
- `<arch>`: the package architecture (table below)

The whole site is **browsable** (static directory indexes are generated on
publish): [ddimension.github.io/openwrt-repo](https://ddimension.github.io/openwrt-repo/)

The **pre-channel path** `https://ddimension.github.io/openwrt-repo/<release>/<arch>/`
stays valid. It is a copy of `stable/<release>/<arch>/`, rewritten by every
stable publish, so devices set up before the channels existed keep working;
see [Migrating](#migrating-devices-set-up-before-the-channels) for moving them
to `stable/`.

Currently built releases: **`snapshot`** (master) and **`openwrt-25.12`**
(openwrt-24.10 is no longer built). Further OpenWrt release branches are added
to the `release:` matrix in the workflow as they appear and show up under the
same URL scheme. A release dropped from the matrix keeps its trees until they
are removed explicitly (`publish-pages.sh --remove`, see
[.github/ci/README.md](.github/ci/README.md)).

| Arch | Covers (among others) |
|---|---|
| `aarch64_cortex-a53` | qualcommax (MikroTik Chateau, ipq807x), mediatek/filogic, ipq60xx |
| `aarch64_cortex-a72` | bcm27xx/bcm2711 (Raspberry Pi 4) |
| `arm_cortex-a15_neon-vfpv4` | ipq806x |
| `arm_cortex-a7_neon-vfpv4` | ipq40xx |
| `mips_24kc` | ath79 (Ubiquiti) |
| `mipsel_24kc` | ramips/mt7621 |
| `x86_64` | x86/64 (VMs, APU, router PCs) |

Every published tree carries a `.published` stamp — UTC publish time, channel,
source commit and Actions run id — which also supplies the dates in the
directory indexes:

```
$ curl -s https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/x86_64/.published
<UTC time> stable <commit sha> <run id>
```

### On the device

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

By name, not from a downloaded file: `apk add ./ddimension-feed-*.apk` records
the package in `/etc/apk/world` pinned to that file's checksum
(`ddimension-feed><Q1…>`), and apk never upgrades a pinned package.

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

#### Switching channels

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

#### Migrating devices set up before the channels

Two things change once for a device that followed this feed before the
channels existed:

- Up to `ddimension-feed` r2 the documented install was from a downloaded
  file, so the package is pinned and the device points at
  `<release>/<arch>/`. That path keeps working — it mirrors stable — but a
  pinned package never picks up a new `ddimension-feed`.
- `wwand` and its LuCI packages moved from date versions to release numbers
  ([Versions](#versions)); apk regards that as a downgrade and keeps the old
  ones.

One command settles both:

```
apk update && apk add ddimension-feed && apk update && apk upgrade --available
```

`apk add ddimension-feed` lifts the pin and installs the current package from
the mirror, whose `.list` names `stable/<release>/<arch>/`; the second
`apk update` reads that tree; `apk upgrade --available` moves every package to
what the repositories offer, for wwand the release version. It does so
system-wide, which on a device whose packages all come from configured feeds
is what you want. For a fleet, run the same over ssh;
`scripts/backup-ap-configs.sh -l -b <broker>` lists the APs known to the MQTT
broker. A
device whose `.list` was written by hand (below) needs `stable/` inserted into
the URL, or the package installed as above.

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

## Device firmware images

Besides the package feed, CI builds **ready-to-flash firmware images** with
the wwand stack (backends, eSIM, LuCI) and `ddimension-feed` baked in — the
exact selection is [`.github/ci/config.wwand`](.github/ci/config.wwand) for
full builds and `PKGS` in
[`build-imagebuilder.sh`](.github/ci/build-imagebuilder.sh) for the
ImageBuilder. `uqmi` is left out on purpose (config.wwand says why). Images
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

Full builds add this feed as `src-git`, pinned to the stable commit that
triggered the run (`…openwrt-repo.git^<sha>`; started by hand: `;stable`). The
ImageBuilder legs pull the packages **signed** from
`stable/<release>/mipsel_24kc/` on gh-pages, after waiting until that tree
carries the `.published` stamp of the triggering commit.

**Triggers:** automatically after every successful feed run on `stable`
(i.e. after every release), and manually via
`gh workflow run build-device-images.yml -R ddimension/openwrt-repo --ref main`.
`-f testing_kernel=true` builds the master legs with `KERNEL_TESTING_PATCHVER`
(stable legs are skipped); those images stay run artifacts and are not
published.

**Where the images live:**

- permanently on gh-pages:
  `https://ddimension.github.io/openwrt-repo/images/<group>/<base>/` —
  `<group>` is `chateau`, `nbg7815` or `zyxel`, `<base>` is `master` or
  `stable`. Flat: the images, `.manifest` (full package list, so you can
  verify the stack), `sha256sums`, `.published`. Each run replaces the
  directories it built; a leg that produced no sysupgrade image keeps the
  previous one.
- as GitHub Actions run artifacts `images-<group>-<base>` (retention 30 days),
  which also contain the per-image package repository:

  ```
  gh run download -R ddimension/openwrt-repo \
    $(gh run list -R ddimension/openwrt-repo -w build-device-images -L1 --json databaseId -q '.[0].databaseId') \
    -n images-zyxel-stable
  ```

  An artifact holds one directory: `<target>-<subtarget>/` for full builds,
  `ramips-mt7621-<base>/` for the ImageBuilder.

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

## Local test builds (before burning CI)

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

## Backing up the fleet's configuration

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

## Updating a package to a newer source commit

Changes go to `main`; stable gets them with the next release.

For `wwand`, `luci-app-wwand` and `luci-proto-wwand` there is one command:

```
scripts/bump-source.sh wwand c27f72e      # development: 1.6.5_p7
scripts/bump-source.sh wwand v1.6.6       # a release:   1.6.6
```

It pins the commit, sets `PKG_VERSION` from `git describe`
([Versions](#versions)), resets or counts `PKG_RELEASE`, and runs
`scripts/update-hashes.sh`; commit the Makefile. A release of the stack: tag
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
