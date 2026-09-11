# ddimension-openwrt-repo — guide for Claude

The OpenWrt package feed, github.com/ddimension/openwrt-repo. Package sessions
reach it as `repository/` from the wwand workspace or at
`~/projects/ddimension-openwrt-repo`. This file holds the rules for changing
packages here; the reasoning and the device side are in `README.md`, CI,
runners and gh-pages in `.github/ci/README.md`. Everything is English.
Commit/push only when asked.

## Branches are channels

| Branch | Publishes | Moves by |
|---|---|---|
| `main` | `…/main/<release>/<arch>/` — development | every commit; this is where you work |
| `stable` | `…/stable/<release>/<arch>/` and the pre-channel path `…/<release>/<arch>/` — releases, device images | `scripts/release-stable.sh` only, and only when the user asks for a release |

- Commit on `main`. Check `git branch --show-current` first — apman-agent's
  `contrib/release.sh` refuses a feed that is not on main, do the same by hand.
- Never commit, push or merge to `stable` yourself. It only moves forward (a
  GitHub ruleset refuses force-push and deletion; every src-git checkout of
  the feed runs `git pull --ff-only`). The hotfix flow in `README.md` is for
  when the user explicitly asks for one.

## Pinning a new source commit

| Package | How |
|---|---|
| `wwand`, `luci-app-wwand`, `luci-proto-wwand` | `scripts/bump-source.sh <pkg> <tag\|commit>` |
| other git-source packages (luacurl, snapcast-mptcp, …) | bump `PKG_SOURCE_VERSION` (+ `PKG_VERSION` or `PKG_SOURCE_DATE` as the Makefile uses them), `PKG_RELEASE`+1, then `scripts/update-hashes.sh <pkg>` |
| `apman` | from apman-agent: `contrib/release.sh` ([apman/README.md](apman/README.md)) |
| `heatingrod`, `q*` | bundled tarball in `files/`, `PKG_HASH` (see the package README) |

- **Versions of the three wwand packages are derived, never typed.**
  `bump-source.sh` takes them from `git describe`: tag `vX.Y.Z` → `X.Y.Z`
  (release material), N commits after it → `X.Y.Z_pN` (main). `PKG_RELEASE`
  is 1 for every new version and counts packaging-only changes. No
  `PKG_SOURCE_DATE` — a date version sorts above every real number in apk.
  `release-stable.sh` refuses to release a `_p` version.
- **A stack release:** tag `vX.Y.Z` in wwand, luci-app-wwand and
  luci-proto-wwand on the commits that belong together (same X.Y.Z in all
  three), `bump-source.sh` each to its tag, commit on main, push once, let
  main build and prove itself — the release itself is the user's call.
- **Pin the commit, not the tag object.** `bump-source.sh` resolves
  `^{commit}`; by hand use `git rev-parse vX.Y.Z^{commit}` — the annotated
  tag's own sha builds a different tarball and the hash check fails.
- **`PKG_MIRROR_HASH` only from the SDK** (`update-hashes.sh`, which
  `bump-source.sh` calls). Host-side replication has produced wrong values.
  The script is all-or-nothing: on `FAILED` it touches no Makefile — read
  `$LOGDIR/hashes.txt`. Do not pipe it and trust the exit status you see.
- One commit per bump, Makefile and hash together: the old Makefile breaks on
  the new tarball.

## CI facts that bite

- A push to `main` builds and publishes main only. `cancel-in-progress` is
  per branch: **one push, then wait** — a burst cancels every run but the
  last. `.md`-only pushes build nothing.
- New package: add it to `.github/ci/packages` (the one list for CI and
  `scripts/local-build.sh`), or say in its README why not (heatingrod,
  pcie_mhi, python3-edlclient).
- gh-pages is written only by `.github/ci/publish-pages.sh`. Never push
  gh-pages by hand, and never re-run a build run from before the channel split
  (2026-09-11): its old publish step deletes `main/` and `stable/`.
- Device images build from stable only, after a green stable run. A change on
  main reaches images with the next release; the image workflow itself always
  runs from main.
- Before pushing CI changes: `docker run --rm -v "$PWD:/repo:ro" -w /repo rhysd/actionlint`
  and `koalaman/shellcheck:stable -x` on the scripts.
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
  Never from a downloaded `.apk` — that pins it in `/etc/apk/world` and it
  never upgrades again.
- Channel switch, migrating old devices (pin + the one-time version
  downgrade, `apk upgrade --available`): `README.md`, "On the device".
