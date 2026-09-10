# heatingrod (OpenWrt package)

PV-surplus heating rod controller v3 (Rust) — ESPHome Native API **server** +
direct connections (powerlogger ESPHome client, DS100 Modbus, SOREL CAN,
1-Wire via kernel w1).

## Source tarball

`files/heatingrod-3.0.0.tar.xz` is a snapshot of the `rust/` workspace from
the heatingrod repository (workspace: crates/esphome-api-server,
crates/heatingrod, tools/dac-safe, vendored esphome-native-api). Regenerate
after source changes:

```bash
# from the heatingrod repo root
tar -cJf ../ddimension-openwrt-repo/heatingrod/files/heatingrod-3.0.0.tar.xz \
  --exclude='rust/target' \
  --exclude='rust/config/production.yaml' \
  --exclude='rust/config/shadow.yaml' \
  --exclude='rust/config/calibration.json' \
  --exclude='rust/config/state.json' \
  --exclude='rust/rust-toolchain.toml' \
  --transform 's|^rust|heatingrod-3.0.0|' rust
sha256sum ../ddimension-openwrt-repo/heatingrod/files/heatingrod-3.0.0.tar.xz
# → PKG_HASH im Makefile aktualisieren
```

`rust-toolchain.toml` is deliberately excluded: the SDK's cargo is not
rustup-managed and would try to download the pinned toolchain.

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
