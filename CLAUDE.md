# ddimension-openwrt-repo — guide for Claude

The OpenWrt package feed, github.com/ddimension/openwrt-repo. Package sessions
reach it as `repository/` from the wwand workspace or at
`~/projects/ddimension-openwrt-repo`. This file holds the rules for changing
packages here; the reasoning and the device side are in `README.md`, CI,
runners and gh-pages in `.github/ci/README.md`. Everything is English.
Commit/push only when asked.

## Two feeds since 2026-10-04

Only the modem world lives here. The add-on packages (apman, snapcast-mptcp,
homesync, the wpad variants, nsca-ng, usb-relay-hid, luacurl, lua-mosquitto,
libubus-lua-async, heatingrod) are in **ddimension/openwrt-addon-feed**, with
their own runners, their own gh-pages site and the same signing key. Nothing
here depends on them. `ddimension-feed` installs one `.list` per feed, so a
device follows both.

**Release order, until the add-on feed has its first release tag:**
`ddimension-feed` r4 names `…/openwrt-addon-feed/<channel>/<release>/<arch>/`
for the channel it was built in. That tree has to exist, or `apk update` on
the device errors with a 404 for it. So: add-on feed first (main build, then a
release tag for its stable channel), and only afterwards may r4 reach THIS
feed's stable — i.e. `scripts/stable-take.sh ddimension-feed` and
`scripts/release-stable.sh` wait for that. On main it is harmless as soon as
the add-on feed has published main once. A non-site-specific change to `publish-pages.sh` or the
release scripts belongs in both repos — say so in the commit message.

## Branches are channels — two independent lines

| Branch | Publishes | Moves by |
|---|---|---|
| `main` | `…/main/<release>/<arch>/` — development, on every push | every commit; this is where you work |
| `stable` | `…/stable/<release>/<arch>/` and the pre-channel path `…/<release>/<arch>/` — releases, device images — **only from a release tag** | cherry-picks, `scripts/stable-take.sh`, fixes made on stable; a push builds but publishes nothing |

- Commit on `main`. Check `git branch --show-current` first.
- `stable` is NOT a pointer onto main: it takes what is ready (`git cherry-pick
  -x`, `scripts/stable-take.sh <pkg>|--ci|--all`) and leaves the rest. Change
  stable only when the user asks for it; it only moves forward (a GitHub
  ruleset refuses force-push and deletion).
- **A release is a tag** on stable: `scripts/release-stable.sh` (only when the
  user asks). It refuses a commit not on origin/stable, without a green build,
  already released, or with a `_p`/`_pre` version (`--allow-dev`). The tag push
  is what publishes stable and starts the device images.
- The wwand stack has the same two lines in its source repos: feed stable pins
  their `stable` (releases `vX.Y.Z` tagged there), feed main their `main`
  (counting `X.Y.Z_preN` from a `vX.Y.Z-dev` marker). See below.
- Device images: prerequisite `image-registry.ddimension.net/myadmin/openwrt-builder:latest`
  (a missing image kills every image leg).

## Pinning a new source commit

| Package | How |
|---|---|
| `wwand`, `luci-app-wwand`, `luci-proto-wwand` | `scripts/bump-source.sh <pkg> <tag\|commit>` |
| other git-source packages (`wwand-qlog`, `wwand-ipa`, `wwand-ipad`, `wwand-rsim`, …) | bump `PKG_SOURCE_VERSION` (+ `PKG_VERSION` or `PKG_SOURCE_DATE` as the Makefile uses them), `PKG_RELEASE`+1, then `scripts/update-hashes.sh <pkg>` |
| `wwand-lpac` | upstream release tarball: `PKG_VERSION` + `PKG_HASH` |
| `heatingrod` | git-archive snapshot of heatingrod-controller in `files/`, `PKG_HASH` ([heatingrod/README.md](heatingrod/README.md)) |
| `ddimension-feed`, `q*` (qfirehose, qflash, qlog) | built from `files/`/a bundled archive in this repo — edit, bump `PKG_RELEASE` |

- **Versions of the three wwand packages are derived, never typed.**
  `bump-source.sh` takes the channel from the checked-out feed branch
  (`--channel` overrides) and the version from `git describe` of the pinned
  commit: on stable from release tags (`vX.Y.Z` → `X.Y.Z`, N after it →
  `X.Y.Z_pN`), on main from the `vX.Y.Z-dev` marker (→ `X.Y.Z_preN`). apk:
  `1.6.10 < 1.6.10_p3 < 1.7.0_pre1 < 1.7.0`, so main sorts above every stable
  patch release. The commit must be on the source branch of the same name.
  `PKG_RELEASE` is 1 for every new version; a packaging-only change is a
  `PKG_RELEASE` bump by hand. No `PKG_SOURCE_DATE` — a date version sorts above
  every real number in apk. `bump-source.sh` refuses the same version for a
  different commit, the wrong source branch, and a lower version (`--force`).
  A source repo without a `stable` branch keeps the one-line derivation.
- **A stack patch release:** fix on source stable (cherry-pick from main, or
  fix there and merge up into main), tag `vX.Y.Z` on source stable in each repo
  that changed, `bump-source.sh` each on feed stable, push (builds), then
  `release-stable.sh` — the release itself is the user's call. **Opening a new
  minor:** merge source main into source stable, tag `vX.Y.0` there, put
  `vX.(Y+1).0-dev` on source main.
- **Pin the commit, not the tag object.** `bump-source.sh` resolves
  `^{commit}`; by hand use `git rev-parse vX.Y.Z^{commit}` — the annotated
  tag's own sha builds a different tarball and the hash check fails.
- **`PKG_MIRROR_HASH` only from the SDK** (`update-hashes.sh`, which
  `bump-source.sh` calls). Host-side replication has produced wrong values.
  `update-hashes.sh` is all-or-nothing (on `FAILED` it touches no Makefile —
  read `$LOGDIR/hashes.txt`), and `bump-source.sh` restores the Makefile when
  it fails. Do not pipe them and trust the exit status you see.
- One commit per bump, Makefile and hash together: the old Makefile breaks on
  the new tarball.

## CI facts that bite

- A push to `main` builds and publishes main only. `cancel-in-progress` is
  per branch: **one push, then wait** — a burst cancels every run but the
  last. `.md`-only pushes build nothing. Only the newest commit of a branch
  publishes: a re-run of an older run builds but does not publish.
- New package: add it to `.github/ci/packages` (the one list for CI and
  `scripts/local-build.sh`), or say in its README why not (heatingrod,
  pcie_mhi, python3-edlclient).
- Every published tree keeps the **last 10 versions** of each package so a
  device can downgrade (`apk add wwand=1.6.9-r1`, which pins it in
  `/etc/apk/world`; `apk add wwand` unpins). The publisher merges the old
  `.apk` in, prunes per package and rebuilds the **signed** index in the
  apk-tools container — so the publish job needs `PRIVATE_KEY` and a registry
  login. A package the build no longer produces is dropped, history included.
- gh-pages is written only by `.github/ci/publish-pages.sh`. Never push
  gh-pages by hand, and never re-run a build run from before the channel split
  (2026-09-11): its old publish step deletes `main/` and `stable/`.
- Device images build from stable releases only, after a green release-tag
  run (or by hand: the newest release tag). The image workflow itself always
  runs from main; the packages come from the release.
- Before pushing CI changes: `docker run --rm -v "$PWD:/repo:ro" -w /repo rhysd/actionlint`
  and `docker run --rm -v "$PWD:/mnt:ro" -w /mnt koalaman/shellcheck:stable -x <scripts>`.
- Anything big: test locally first,
  `RELEASES=snapshot ARCHS=x86_64 PACKAGES="<pkg>" scripts/local-build.sh`
  (the mandatory `--ulimit nofile` is inside the script).

## What is live

- `curl -s https://ddimension.github.io/openwrt-repo/<channel>/<release>/<arch>/.published`
  → UTC time, channel, source commit, run id of that tree.
- `gh run list -R ddimension/openwrt-repo -w build -L 5` (and `-w build-device-images`).
- On a device: `apk list -I 'wwand*'`, `cat /etc/apk/repositories.d/ddimension.list`.

## Devices

- Set up with `ddimension-feed`, installed **by name** from the tree:
  `apk --allow-untrusted -X https://ddimension.github.io/openwrt-repo/stable/<release>/<arch>/packages.adb add ddimension-feed`.
  From a downloaded `ddimension-feed.apk` only with `apk update && apk add
  ddimension-feed` afterwards — a file install is pinned in `/etc/apk/world`
  and a plain `apk upgrade` never moves it again.
- Channel switch, migrating old devices (pin + the one-time version
  downgrade, `apk add -u ddimension-feed`, `apk upgrade --available`):
  `README.md`, "How-tos".
