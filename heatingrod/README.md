# heatingrod (OpenWrt package)

PV-surplus heating rod controller v3 (Rust) — ESPHome Native API **server** +
direct connections (powerlogger ESPHome client, DS100 Modbus, SOREL CAN,
1-Wire via kernel w1).

## Source tarball

`files/heatingrod-3.0.0.tar.xz` is a snapshot of
[ddimension/heatingrod-controller](https://github.com/ddimension/heatingrod-controller),
where the Rust v3 workspace lives since 2026-09-05 (it was `rust/` in the
heatingrod repository before). Workspace: crates/esphome-api-server,
crates/heatingrod, tools/dac-safe, vendored esphome-native-api. Regenerate
after source changes, from committed state:

```bash
cd ~/projects/heatingrod-controller
git archive --format=tar --prefix=heatingrod-3.0.0/ HEAD \
  Cargo.toml Cargo.lock .gitignore README.md crates tools vendor config plan systemd tests-py \
  | xz > ~/projects/ddimension-openwrt-repo/heatingrod/files/heatingrod-3.0.0.tar.xz
sha256sum ~/projects/ddimension-openwrt-repo/heatingrod/files/heatingrod-3.0.0.tar.xz
# -> PKG_HASH in the Makefile, and PKG_RELEASE+1 so devices upgrade
#    (a new PKG_VERSION renames the tarball and the --prefix with it)
```

`git archive` takes tracked files only, so the installation's own files —
`config/production.yaml`, `shadow.yaml`, `calibration.json`, `state.json`,
all untracked — cannot end up in the package. The explicit path list leaves
out `docs/`, `grafana/`, `LICENSE`, `CLAUDE.md` and `rust-toolchain.toml`,
the last one deliberately: the SDK's cargo is not rustup-managed and would try
to download the pinned toolchain. The bundled tarball predates
`config/production.example.yaml`, so the first regeneration changes
`PKG_HASH` even without a source change.

Changes to this package follow the feed's rules (`CLAUDE.md` at the feed
root): commit on `main`; `stable` gets it with the next release.

## Build requirements

- `PKG_BUILD_DEPENDS:=rust/host` builds rustc+cargo+LLVM **from source**
  (packages feed, `x.py dist` with `download-ci-llvm=false`). Peak disk
  usage ~35-45GB in the build dir — a 49G Docker LV is too small for a
  local SDK build alongside existing volumes (04.09.2026: failed with
  "No space left on device" twice). Options: extend the Docker LV, move
  the Docker data-root to a bigger filesystem, or provision a prebuilt
  rust toolchain per arch instead of the source build.
- Local test build: `RELEASES=snapshot ARCHS=x86_64 PACKAGES=heatingrod scripts/local-build.sh`
- Runtime deps: `+kmod-w1 +kmod-w1-master-ds2490 +kmod-w1-slave-therm`
  (1-Wire via kernel w1/sysfs, since 2026-09-04 — no libowcapi).

## Config

`/etc/heatingrod/config.yaml` (template installed from files/config.yaml,
CHANGE-ME placeholders). Schema is 1:1 with the Debian production config.
