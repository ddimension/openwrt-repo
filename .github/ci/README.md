# CI- und Build-Infrastruktur

Alles läuft auf **eigenen self-hosted Runnern** (n1–n4). `ddimension` ist ein
**User-Account, keine Org** → Runner sind **repo-scoped an dieses Repo**; geteilte/
Org-Runner gibt es nicht. Deshalb liegen auch die Image-Build-Workflows hier (nicht
im openwrt-Fork), obwohl sie OpenWrt-Quellen bauen — der Fork hat keine Runner und
Actions ist dort aus.

Zwei Workflows:
- **`build.yml`** — baut den wwand-**Paket-Feed** und published apk-Repos nach
  gh-pages (`https://ddimension.github.io/openwrt-repo/<release>/<arch>/`).
- **`build-device-images.yml`** — baut fertige **Firmware-Images** (chateau, nr7101,
  lte3301-plus), je für master und stable, mit komplettem wwand-Stack.

---

## Runner (n1–n4)

- Je ein **PVE-OCI-Container** (PVE 9.1+, `pct create <ctid> <oci-image>`), **immer
  unprivilegiert**. Basis: `myoung34/github-runner` + Docker.
- Erstellt aus `~/projects/containers/openwrt-runner/` (Image via `mkimg`) mit
  `pct-create-runner.sh` (CT-Anlage). Registriert repo-scoped, Label **`openwrt`**.
- Verteilung: GitHubs Queue ist pull-basiert → gleiches Label genügt, die Matrix
  verteilt sich selbst; schnellere Box zieht mehr. Mehr Durchsatz = mehr CT-Instanzen
  pro Node, `--cores`/`-j` je Box deckeln (hier `-j10`, 12 P-Cores).

### Harte Regeln / Fallstricke (teuer gelernt)

- **Nie privilegiert.** `--unprivileged 1` immer. Docker im CT braucht
  `--docker` → `nesting=1,keyctl=1`.
- **ulimit:** Der SysV-Docker-Init (`/etc/init.d/docker`) setzt `ulimit -u/-p
  unlimited` → im unprivilegierten LXC „Operation not permitted", Service bricht ab.
  Fix im `openwrt-runner`-Image: alle `ulimit`-Zeilen nicht-fatal machen; zusätzlich
  `lxc.prlimit.nofile`. **Wichtig:** Fix wirkt erst nach `mkimg` (Image-Neubau) —
  ein alter Registry-Stand hat ihn nicht.
- **containerd-Zombie:** *Niemals* `dockerd` manuell starten. Ein zweiter dockerd
  hinterlässt einen verwaisten containerd → der Service-dockerd bringt danach
  „timeout waiting for containerd". Nur der Container-Entrypoint (`START_DOCKER_SERVICE`)
  startet Docker.
- **DHCP braucht AppArmor.** Die Hosts laufen mit `apparmor=0`; PVEs host-managed
  dhclient (via `aa-exec`) scheitert → **statische IP** (`--ip <CIDR> --gw <GW>`).
- **`--data`:** separates Volume unter `/var/lib/docker` (Docker-/Build-I/O),
  rootfs klein (`--disk`, default 4–8 G). Die Cache-Named-Volumes liegen darauf →
  persistent bis CT-Neuerzeugung.
- **Token:** GitHub-**PAT** (fine-grained, Repo-Permission *Administration: RW*) oder
  Registration-Token (`--token-kind reg`, kurzlebig). **Kein** Docker-PAT (`dckr_pat…`)!

Beispiel-Anlage:
```bash
cd ~/projects/containers/openwrt-runner && ./mkimg
./pct-create-runner.sh --storage lvm-thin --ctid 300 --name n1 \
  --token-file github-token --docker --data 80 --ip 10.0.0.51/24 --gw 10.0.0.1 --console
gh api repos/ddimension/openwrt-repo/actions/runners   # online? Label openwrt?
```

---

## Container-Images (`~/projects/containers`)

Beide via `<dir>/mkimg` (Hash-basiert: baut+pusht nur bei Änderung an Dockerfile/
packages/Base-Digest) nach `image-registry.ddimension.net/myadmin/…`.

- **`openwrt-runner`** — `FROM myoung34/github-runner` + ulimit-Fix. Nur Runner +
  Docker (bewusst **keine** Build-Deps: gebaut wird in gh-action-sdk bzw.
  `openwrt-builder`).
- **`openwrt-builder`** — `FROM debian:trixie-slim` + volle OpenWrt-Build-Deps +
  Nicht-root-User `builder` (uid 1000). Für Voll-Image-Builds. (Registry hat kein
  debian-Mirror → Basis direkt von Docker Hub.)

---

## Workflow 1: `build.yml` (Paket-Feed)

- Baut die wwand-Pakete via **gevendorter** `openwrt/gh-action-sdk`
  (`.github/actions/openwrt-sdk`), Matrix Release × Arch, published apk-Repos nach
  gh-pages (`force_orphan`).
- **Docker-basiert** (gh-action-sdk = `docker run` des SDK-Containers, `docker/login`,
  peaceiris gh-pages-Action) → Runner braucht Docker.
- **Cache** (node-lokale Named Volumes, arch-übergreifend geteilt, angelegt+gechownt
  auf uid 1000): `openwrt-dl`→`/dl`, `openwrt-ccache`→`/ccache`.
  - dl: OpenWrt nutzt `$(TOPDIR)/dl` → im Entrypoint `dl`→`/dl` symlinken.
  - ccache: OpenWrt ignoriert die `CCACHE_DIR`-Env und nutzt `$(TOPDIR)/.ccache`
    (rules.mk) → `.ccache`→`/ccache` symlinken (nicht via Env!).
- SDK-Release-Images cachet Docker auf dem Node automatisch → **kein
  `docker image prune -a`.**

---

## Workflow 2: `build-device-images.yml` (Firmware-Images)

Dispatch: `gh workflow run build-device-images.yml -R ddimension/openwrt-repo --ref main`.
Artefakte: `images-chateau-{master,stable}`, `images-zyxel-{master,stable}`.

### chateau (MikroTik Chateau 5G R17 ax) — Voll-Buildroot

Kein ImageBuilder möglich: neues Gerät **nur im PR** (+ Kernel-Patch
`routerbootpart.c`, eigenes DTS, LZMA-Loader). Quelle:
- **master:** Fork-Branch `pr-mikrotik-chateau-5g-r17-ax`.
- **stable:** Fork-Branch `chateau-stable-backport` = `openwrt-25.12` + PR gecherry-pickt.
  Konflikte beim Backport in `02_network` und `11-ath11k-caldata` (master gruppiert dort
  andere Geräte) → nur den Chateau-Block einfügen, master-Kontext weglassen.
- Cache: `owrt-src-chateau-<base>` (Quellbaum **inkl. build_dir/staging** persistent) +
  geteilt `owrt-dl`/`owrt-ccache`. `CONFIG_CCACHE_DIR=/ccache`, `dl`→`/dl`.
- wwand komplett: `.github/ci/config.wwand`; wwand-Feed via `src-git` aus diesem Repo.
- Skript: `.github/ci/build-images.sh`.

**Backport pflegen** (wenn sich der PR ändert): PR neu auf `openwrt-25.12` cherry-picken,
Konflikte wie oben lösen, `chateau-stable-backport` force-pushen.

### zyxel (nr7101 + lte3301-plus) — ImageBuilder

Beide **upstream** → offizieller ramips/mt7621-ImageBuilder (snapshot bzw. neuestes
`25.12.x`), **kein** Toolchain-Build. wwand kommt **signiert** aus gh-pages:
- apk-IB nutzt die Datei **`repositories`** (eine `packages.adb`-URL je Zeile) und
  vertraut allen **`.pem`** in `keys/`; `CONFIG_SIGNATURE_CHECK=y` (default) prüft.
- Also: `keys/ddimension.pem` (aus `.github/ci/keys/ddimension-public-key.pem`) +
  `…/<snapshot|openwrt-25.12>/mipsel_24kc/packages.adb` an `repositories` anhängen.
- Arch mt7621 = `mipsel_24kc`. Skript: `.github/ci/build-imagebuilder.sh`.

---

## Betrieb — Kurzreferenz

- **Image-Build starten:** `gh workflow run build-device-images.yml -R ddimension/openwrt-repo --ref main`
- **Runner-Status:** `gh api repos/ddimension/openwrt-repo/actions/runners`
- **Container-Image neu bauen:** `cd ~/projects/containers/<name> && ./mkimg`
- **Neues Gerät:** upstream → in die `zyxel`-`DEVICES` aufnehmen; mit Source-Änderungen
  → eigene chateau-artige Voll-Build-Leg.
- **ccache/dl prüfen (Node):**
  `pct exec <ctid> -- du -sh /var/lib/docker/volumes/openwrt-{dl,ccache}/_data`
- Ein reiner `.md`-Push triggert **keinen** Feed-Build (`paths-ignore: ['**.md']`).
