#!/usr/bin/env python3
"""Keep the last N versions of each package in one published tree.

Runs INSIDE the apk-tools container (.github/ci/apk-retention.sh starts it);
nothing here is meant to run on a runner, which has no apk.

What it does, in one directory:

  1. groups the .apk files by package name and sorts each group by version —
     with `apk version -t`, so the order is apk's own, not a string sort;
  2. deletes everything but the newest N of each name;
  3. writes versions.json (and .versions.tsv, the same for the shell that
     builds the directory listing): per file the version, size, when the
     package was BUILT and when we first PUBLISHED it, carried over from the
     previous versions.json so the publish date survives (git stores no
     mtimes, so a file's mtime on the site is the checkout time and lies);
  4. rebuilds packages.adb over exactly the files that remain and signs it;
  5. rebuilds index.json from that index with OpenWrt's own generator.

Order matters: the index is written last, over the files that survived, so the
tree can never advertise a version whose file was just pruned.

Files that are not <name>-<version>.apk are left alone and kept out of the
index — the versionless ddimension-feed.apk is deliberately not a package of
the repository (build.yml copies it next to the index for the download link).
"""

import argparse
import functools
import json
import os
import re
import subprocess
import sys

APK = re.compile(r"^(?P<name>.+)-(?P<version>[^-]+-r\d+)\.apk$")


def die(msg):
    print(f"apk-retention: {msg}", file=sys.stderr)
    sys.exit(1)


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, text=True, capture_output=True, **kw)


def vcmp(a, b):
    """apk's own version order: -1, 0, 1 for a <, ==, > b."""
    out = run(["apk", "version", "-t", a, b]).stdout.strip()
    return {"<": -1, "=": 0, ">": 1}.get(out, 0)


def built_at(path):
    """When the package was built: the newest mtime its payload carries.

    OpenWrt stamps every file in a package with SOURCE_DATE_EPOCH, so this is
    stable across rebuilds of the same source — unlike the file's own mtime.
    The index itself carries no build time, hence reading the package.
    """
    out = run(["apk", "adbdump", path]).stdout
    times = [int(m) for m in re.findall(r"^\s*mtime:\s*(\d+)\s*$", out, re.M)]
    return max(times) if times else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--keep", type=int, required=True)
    ap.add_argument("--arch", required=True)
    ap.add_argument("--key", help="signing key; unsigned index without it")
    args = ap.parse_args()
    if args.keep < 1:
        die("--keep must be at least 1")
    os.chdir(args.dir)

    groups = {}
    for f in sorted(os.listdir(".")):
        m = APK.match(f)
        if m:
            groups.setdefault(m["name"], []).append((m["version"], f))

    # 1 + 2: newest N per name, the rest goes
    dropped = []
    keep = []
    for name, versions in sorted(groups.items()):
        versions.sort(key=functools.cmp_to_key(lambda a, b: vcmp(a[0], b[0])), reverse=True)
        for version, f in versions[args.keep:]:
            os.remove(f)
            dropped.append(f)
        keep += [f for _, f in versions[: args.keep]]
    keep.sort()

    # 3: versions.json — the publish date of a file we already had must not
    # move, it is the only durable "since when is this version available".
    old = {}
    if os.path.exists("versions.json"):
        try:
            with open("versions.json") as fh:
                old = json.load(fh)
        except (OSError, ValueError) as e:
            print(f"apk-retention: ignoring unreadable versions.json ({e})")
    now = os.environ.get("PUB_TIME", "")
    commit = os.environ.get("PUB_COMMIT", "")
    run_id = os.environ.get("PUB_RUN", "")
    versions = {}
    for f in keep:
        m = APK.match(f)
        entry = dict(old.get(f) or {})
        entry.update(name=m["name"], version=m["version"], size=os.path.getsize(f))
        if not entry.get("built"):
            b = built_at(f)
            if b:
                entry["built"] = b
        if not entry.get("published"):
            entry["published"] = now
            entry["commit"] = commit
            entry["run"] = run_id
        versions[f] = entry
    with open("versions.json", "w") as fh:
        json.dump(versions, fh, indent=1, sort_keys=True)
        fh.write("\n")
    # The same thing the directory listing needs, in a form a shell can read
    # without a JSON parser (publish-pages.sh runs on a runner that has no apk
    # and should not need python either). A dotfile, so it is not listed.
    with open(".versions.tsv", "w") as fh:
        for f in keep:
            e = versions[f]
            fh.write("\t".join([
                f, e["version"], str(e.get("built") or ""), e.get("published") or "",
            ]) + "\n")

    # 4: the index over exactly what is left. mkndx cannot append (-x only
    # reuses metadata), so every file is named here.
    cmd = ["apk", "mkndx", "--allow-untrusted", "--output", "packages.adb"]
    if args.key:
        cmd += ["--sign", args.key]
    try:
        out = run(cmd + keep).stdout.strip()
    except subprocess.CalledProcessError as e:
        die(f"apk mkndx failed: {e.stderr.strip() or e}")
    print(f"apk-retention: {out}")

    # 5: index.json, with OpenWrt's generator, so the file stays what the SDK
    # would have written.
    adb = run(["apk", "adbdump", "--format", "json", "packages.adb"]).stdout
    idx = subprocess.run(
        [sys.executable, "/ci/make-index-json.py", "-f", "apk", "-a", args.arch, "-"],
        input=adb, text=True, capture_output=True, check=True,
    ).stdout
    with open("index.json", "w") as fh:
        fh.write(idx)

    multi = {n: len(v) for n, v in groups.items() if len(v) > 1}
    print(
        f"apk-retention: {len(keep)} files, {len(groups)} packages, "
        f"{len(multi)} of them with several versions, {len(dropped)} dropped"
        + (f" ({', '.join(dropped)})" if dropped else "")
    )


if __name__ == "__main__":
    main()
