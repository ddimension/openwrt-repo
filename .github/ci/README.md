# CI- und Build-Infrastruktur

Alles läuft auf **eigenen self-hosted Runnern** (derzeit n5–n7). `ddimension` ist
ein **User-Account, keine Org** → Runner sind **repo-scoped an dieses Repo**;
geteilte/Org-Runner gibt es nicht. Deshalb liegen auch die Image-Build-Workflows
hier (nicht im openwrt-Fork), obwohl sie OpenWrt-Quellen bauen — der Fork hat
keine Runner und Actions ist dort aus.

Zwei Branches = zwei Kanäle des Feeds (Details: Haupt-README, „Branches and
channels“): **`main`** = Entwicklung, **`stable`** = Releases
(`scripts/release-stable.sh`: Fast-Forward + Tag `YYYY.MM.DD`).

Zwei Workflows:
- **`build.yml`** — baut den **Paket-Feed** für den gepushten Branch und
  publiziert ihn nach `https://ddimension.github.io/openwrt-repo/<kanal>/<release>/<arch>/`;
  stable zusätzlich in den Alt-Pfad `<release>/<arch>/`.
- **`build-device-images.yml`** — baut fertige **Firmware-Images** (chateau,
  nbg7815, nr7101, lte3301-plus) mit wwand-Stack und `ddimension-feed`, immer
  gegen den **stable**-Kanal.

Beide schreiben gh-pages **ausschließlich** über `.github/ci/publish-pages.sh`.

---

## Runner

- Je ein **PVE-OCI-Container** (PVE 9.1+, `pct create <ctid> <oci-image>`), **immer
  unprivilegiert**. Basis: `myoung34/github-runner` + Docker.
- Erstellt aus `~/projects/containers/openwrt-runner/` (Image via `mkimg`) mit
  `pct-create-runner.sh` (CT-Anlage). Registriert repo-scoped, Label **`openwrt`**
  (steht auch in `.github/actionlint.yaml`).
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
- **Geteiltes Checkout-Verzeichnis.** Alle Jobs beider Workflows teilen sich auf
  einem Runner *dasselbe* Workspace-Verzeichnis. Früher checkte
  `build-device-images.yml` per `sparse-checkout` nur `.github` aus; ein danach auf
  demselben Runner laufender Feed-Checkout materialisierte den Rest **nicht**
  zuverlässig zurück → Workspace = nur `.git`/`.github` → `/feed` leer →
  `No feed for package 'apman'` → **alle** Feed-Jobs rot (Symptom:
  `Collecting package info: feeds/wwand` = 0×). Die Ursache ist beseitigt — kein
  Job checkt mehr sparse aus. Trotzdem beginnt **jeder** Job beider Workflows
  identisch mit `rm -rf "${GITHUB_WORKSPACE:?}"/*` + vollem Checkout, damit kein
  alter Workspace-Stand durchschlägt. (`docker cp`/Named-Volumes waren damals eine
  **Fehlspur** — der Bind-Mount war korrekt, nur die Quelle leer.) Eine lokale
  Composite-Action dafür geht nicht: die gibt es erst nach dem Checkout.

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

## gh-pages: ein Schreiber (`publish-pages.sh`)

Layout der Site:

```
/keys/…                        Signaturschlüssel (nur überlagert, nie gelöscht)
/main/<release>/<arch>/        Entwicklungskanal   (nur main-Läufe)
/stable/<release>/<arch>/      Release-Kanal       (nur stable-Läufe)
/<release>/<arch>/             Alt-Pfad = Kopie von stable (nur stable-Läufe)
/images/<gruppe>/<base>/       Device-Images (build-device-images.yml)
```

- **`SRC=DEST` ersetzt genau `DEST`, sonst nichts.** Der andere Kanal und die
  Images bleiben stehen. Es gibt **keine** Bereinigung der Wurzel mehr: main und
  stable publizieren jeweils mit dem Skript *ihres* Branches, eine Keep-Liste in
  der älteren Version würde löschen, was die neuere angelegt hat. Entfernen nur
  explizit mit `--remove`.
- **Guards:** ein Feed-Ziel wird nur mit `SRC/packages.adb` ersetzt, ein
  `images/`-Ziel nur mit mindestens einer `*sysupgrade*`-Datei. Ein halb
  gescheiterter Lauf überschreibt keinen guten Stand.
- **Nebenläufigkeit:** Push als Compare-and-Swap (`--force-with-lease` gegen den
  Commit, auf dem die neue Site gebaut wurde); wer verliert, liest neu, wendet
  seine Änderung erneut an und versucht es wieder (bis 10×). **Keine**
  `concurrency`-Gruppe dafür: GitHub hält pro Gruppe nur *einen* wartenden Lauf
  und bricht den älteren wartenden ab — ein wartender stable-Publish ginge
  verloren.
- **Ein orphan-Commit** (Branch wächst nie), erzeugt im Clone des aktuellen
  Stands → ein Push überträgt nur neue Objekte.
- **`.published`** in jedem ersetzten Verzeichnis:
  `<UTC-Zeit> <kanal> <quell-commit> <run-id>`. Daraus kommen die Daten in den
  Verzeichnis-Indexen (die mtime wäre für alles, was der Lauf nicht geschrieben
  hat, die Checkout-Zeit), und darauf wartet der zyxel-Leg.
- **Token** nur über env-gescopte git-Config (`GIT_CONFIG_*`), nie in einer
  Clone-URL — die landete früher in `.git/config` im persistenten Workspace.
- **Alte Läufe nie re-runnen.** Ein Lauf von *vor* der Kanal-Trennung hat noch den
  alten Publish mit Keep-Liste (`keys|index.html|images|openwrt-*|snapshot`) und
  force-pusht ohne Lease — er löscht `main/` und `stable/`. Dasselbe gilt für
  einen Dispatch auf alten Branches, die noch das alte `build.yml` tragen.

Nicht mehr gebautes Release entfernen (lokal, eigenes Token):
```bash
GITHUB_REPOSITORY=ddimension/openwrt-repo GH_TOKEN="$(gh auth token)" \
  .github/ci/publish-pages.sh -m "drop openwrt-24.10" \
  --remove main/openwrt-24.10 --remove stable/openwrt-24.10 --remove openwrt-24.10
```

Lokal testen: `PAGES_REMOTE=/pfad/zu/bare.git PAGES_BACKOFF="1 2"` richtet das
Skript auf ein Bare-Repo statt auf GitHub.

---

## Workflow 1: `build.yml` (Paket-Feed)

- **Auslöser:** Push auf `main` oder `stable` (reine `.md`-Pushes nicht:
  `paths-ignore`), `workflow_dispatch`. Ein Dispatch auf einem anderen Branch
  baut nur, publiziert nicht.
- **Kanal = Branch:** `DDIMENSION_FEED_CHANNEL` (Workflow-env) bestimmt das
  Publish-Ziel und die URL, die `ddimension-feed` auf Geräten einträgt.
- **Concurrency je Branch** (`build-<branch>`, cancel-in-progress): ein neuer
  main-Push bricht nur den laufenden main-Build ab, nie stable.
- **Paketliste:** `.github/ci/packages` (auch Default von `scripts/local-build.sh`).
  Leer = Fehler, denn eine leere `PACKAGES` baut im SDK den ganzen Feed.
- Baut via **gevendorter** `openwrt/gh-action-sdk` (`.github/actions/openwrt-sdk`),
  Matrix Release × Arch. **Docker-basiert** (gh-action-sdk = `docker run` des
  SDK-Containers, `docker/login`) → Runner braucht Docker.
- **Cache** (node-lokale Named Volumes, arch-übergreifend geteilt, angelegt+gechownt
  auf uid 1000): `openwrt-dl`→`/dl`, `openwrt-ccache`→`/ccache`.
  - dl: OpenWrt nutzt `$(TOPDIR)/dl` → im Entrypoint `dl`→`/dl` symlinken.
  - ccache: OpenWrt ignoriert die `CCACHE_DIR`-Env und nutzt `$(TOPDIR)/.ccache`
    (rules.mk) → `.ccache`→`/ccache` symlinken (nicht via Env!).
- SDK-Release-Images cachet Docker auf dem Node automatisch → **kein
  `docker image prune -a`.**
- **publish**-Job: auch wenn einzelne Legs rot sind (`!cancelled()`); Legs ohne
  Artefakt behalten ihren publizierten Stand. Ruft `publish-pages.sh` mit
  `<kanal>/<release>/<arch>` je gebautem Leg, bei stable zusätzlich `<release>/<arch>`.

---

## Workflow 2: `build-device-images.yml` (Firmware-Images)

**Auslöser:**
- **Automatisch** nach jedem erfolgreichen Feed-Lauf (`build`) auf **`stable`** —
  via `workflow_run` (nur bei `conclusion == success`). main-Läufe lösen nichts aus.
  `concurrency` verhindert Stapeln.
- **Manuell:** `gh workflow run build-device-images.yml -R ddimension/openwrt-repo --ref main`
  (`-f testing_kernel=true`: master-Legs mit Testkernel, stable übersprungen, kein
  Publish).

**`workflow_run`-Semantik:** GitHub führt immer die Workflow-Datei und den Checkout
des **Default-Branch (main)** aus. Die Skripte unter `.github/ci` kommen also von
main (Änderungen wirken sofort), die Pakete kommen explizit aus stable
(`FEED_CHANNEL: stable` im Workflow-env).

**Ort der Images:**
- dauerhaft auf gh-pages unter `images/<gruppe>/<base>/`
  (`<gruppe>` = chateau | nbg7815 | zyxel, `<base>` = OpenWrt-Basis master |
  stable), flach, ohne Paket-Repo, mit `.published`;
- als **Run-Artefakte** `images-<gruppe>-<base>` (Retention **30 Tage**,
  `if-no-files-found: warn`). Holen:
  `gh run download <run-id> -R ddimension/openwrt-repo -n images-zyxel-stable`
  (bei „path traversal" das Artefakt-Zip roh über die API ziehen —
  `gh api …/artifacts/<id>/zip`). Dateibaum im Artefakt: Voll-Build
  `<target>-<subtarget>/…`, ImageBuilder `ramips-mt7621-<base>/…`, jeweils
  `…-sysupgrade.bin` + `.manifest` (Paketliste inkl. wwand-Stack).

`master`/`stable` in den Matrizen ist die **OpenWrt-Basis**, nicht der Feed-Kanal.
Die Namen bleiben, weil Volumes (`owrt-src-<slug>-<base>`, `owrt-ib-<base>`) und
Artefakte daran hängen — ein Rename kostet den chateau-Leg sein warmes `build_dir`
(~12 h Kaltbau).

### Voll-Buildroot (chateau, nbg7815)

Kein ImageBuilder möglich: die Geräte gibt es **nur in PR-Branches** des Forks
`ddimension/openwrt` (chateau zusätzlich Kernel-Patch `routerbootpart.c`, eigenes
DTS, LZMA-Loader). Quellen:
- **chateau master:** Fork-Branch `chateau-ci` = openwrt main + Device-Support
  (#24335) + QCA8081-2.5G-TX-Clock-Fix (#24566) + ath11k-Reboot-Fix (#24601). Die
  einzelnen PR-Branches bleiben sauber für upstream; `chateau-ci` trägt alle drei,
  damit das Image wirklich läuft.
- **chateau stable:** Fork-Branch `chateau-stable-backport` = `openwrt-25.12` + PR
  gecherry-pickt. Konflikte beim Backport in `02_network` und `11-ath11k-caldata`
  (master gruppiert dort andere Geräte) → nur den Chateau-Block einfügen,
  master-Kontext weglassen.
- **nbg7815 (nur master):** Fork-Branch `nbg7815-update` (RGB-LED, Bluetooth,
  Lüfter/Temperatursensor, 160-MHz-Boardfile-Schalter). Für stable gibt es keinen
  Backport-Branch.
- **wwand-Feed:** `src-git` dieses Repos, nach `workflow_run` gepinnt auf den
  auslösenden stable-Commit (`…openwrt-repo.git^<sha>`), bei Dispatch
  `…openwrt-repo.git;stable`. `scripts/feeds` merkt sich die Quelle
  (`feeds/wwand.tmp/location`) und klont bei Änderung neu → der persistente
  Quellbaum zieht sauber mit.
- Stack: `.github/ci/config.wwand` (inkl. `ddimension-feed`). Skript:
  `.github/ci/build-images.sh`.
- Cache: `owrt-src-<slug>-<base>` (Quellbaum **inkl. build_dir/staging** persistent) +
  geteilt `owrt-dl`/`owrt-ccache`. `CONFIG_CCACHE_DIR=/ccache`, `dl`→`/dl`.
- **Lokal nachbauen:** `scripts/local-image-build.sh` (podman/docker, Resume,
  ccache-Ordner, andere Geräte/Archs) — Doku im Haupt-README.

**Backport pflegen** (wenn sich der PR ändert): PR neu auf `openwrt-25.12` cherry-picken,
Konflikte wie oben lösen, `chateau-stable-backport` force-pushen.

### zyxel (nr7101 + lte3301-plus) — ImageBuilder

Beide **upstream** → offizieller ramips/mt7621-ImageBuilder (snapshot bzw. neuestes
`25.12.x`), **kein** Toolchain-Build. wwand kommt **signiert** aus gh-pages:
- apk-IB nutzt die Datei **`repositories`** (eine `packages.adb`-URL je Zeile) und
  vertraut allen **`.pem`** in `keys/`; `CONFIG_SIGNATURE_CHECK=y` (default) prüft.
- Also: `keys/ddimension.pem` + `…/stable/<snapshot|openwrt-25.12>/mipsel_24kc/packages.adb`
  an `repositories` anhängen.
- **Warten auf den Feed:** nach `workflow_run` pollt der Job
  `…/stable/<release>/mipsel_24kc/.published`, bis dort der auslösende Commit steht
  (max. 20 min, danach Warnung und Bau gegen den publizierten Stand). Früher: die
  Pages-Build-API — ungenau, sobald ein main-Publish dazwischenkommt.
- Arch mt7621 = `mipsel_24kc`. Skript: `.github/ci/build-imagebuilder.sh`
  (Paketliste `PKGS`, inkl. `ddimension-feed`).

---

## Betrieb — Kurzreferenz

- **Release:** `scripts/release-stable.sh` (Fast-Forward stable + Tag, fragt vor dem
  Push; verweigert `_p`-Versionen von wwand/LuCI). Hotfix-Weg: Haupt-README.
- **wwand/LuCI-Quelle pinnen:** `scripts/bump-source.sh <paket> <tag|commit>` —
  Version aus `git describe` (`vX.Y.Z` → `X.Y.Z`, danach `X.Y.Z_pN`), setzt
  `PKG_RELEASE` und rechnet den Mirror-Hash im SDK-Container.
- **Feed-Build von Hand:** `gh workflow run build.yml -R ddimension/openwrt-repo --ref stable`
  (bzw. `--ref main`). Nötig u. a., wenn ein neuer Branch ohne neue Commits
  gepusht wurde — GitHub startet dann wegen `paths-ignore` ggf. keinen Lauf.
- **Image-Build starten:** `gh workflow run build-device-images.yml -R ddimension/openwrt-repo --ref main`
- **Was ist live?** `curl -s https://ddimension.github.io/openwrt-repo/stable/openwrt-25.12/x86_64/.published`
- **Runner-Status:** `gh api repos/ddimension/openwrt-repo/actions/runners`
- **Workflows linten:** `docker run --rm -v "$PWD:/repo:ro" -w /repo rhysd/actionlint`
- **Container-Image neu bauen:** `cd ~/projects/containers/<name> && ./mkimg`
- **Neues Gerät:** upstream → in die `zyxel`-`DEVICES` aufnehmen; mit Source-Änderungen
  → eigene Voll-Build-Zeile in der `fullbuild`-Matrix (wie nbg7815).
- **ccache/dl prüfen (Node):**
  `pct exec <ctid> -- du -sh /var/lib/docker/volumes/openwrt-{dl,ccache}/_data`
- **Alte Läufe** (vor der Kanal-Trennung) **nie** re-runnen — siehe gh-pages-Abschnitt.
