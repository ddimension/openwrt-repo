#!/usr/bin/env python3
"""Audit the MHI vendor import without compiling the driver."""

import argparse
import pathlib
import re


def normalized(text):
    return "\n".join(re.sub(r"^ +(?=\t)", "", line.rstrip())
                     for line in text.splitlines()).rstrip("\n")


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--package", type=pathlib.Path, default=pathlib.Path(__file__).parent)
parser.add_argument("--vendor", type=pathlib.Path, required=True)
args = parser.parse_args()
source = args.package / "src"
checked = 0

artifacts = sorted(
    str(path)
    for package in (args.package, args.package.parent / "rmnet-nss")
    for path in package.rglob("*")
    if path.name.endswith((".o", ".ko", ".cmd", ".mod", ".mod.c"))
    or path.name in ("Module.symvers", "modules.order")
    or ".tmp_versions" in path.parts
)
assert not artifacts, "Generated build artifacts: " + ", ".join(artifacts)

for vendor_file in sorted(args.vendor.rglob("*")):
    relative = vendor_file.relative_to(args.vendor)
    if not vendor_file.is_file() or "log" in relative.parts:
        continue
    imported = source / relative
    assert imported.is_file(), f"Missing vendor file: {relative}"
    if str(relative) == "devices/mhi_netdev_quectel.c":
        continue
    expected = vendor_file.read_text()
    if str(relative) == "core/mhi.h":
        expected = expected.replace('printk(KERN_DEBUG "[I][mhi%d][%s] "',
                                    'pr_debug("[I][mhi%d][%s] "')
    if str(relative) == "core/mhi_init.c":
        expected = expected.replace("mhi_cntrl->klog_lvl = MHI_MSG_LVL_VERBOSE;",
                                    "mhi_cntrl->klog_lvl = MHI_MSG_LVL_ERROR;")
    if str(relative) == "devices/mhi_uci.c":
        expected = expected.replace("static int uci_msg_lvl = MHI_MSG_LVL_VERBOSE;",
                                    "static int uci_msg_lvl = MHI_MSG_LVL_ERROR;")
    assert normalized(imported.read_text()) == normalized(expected), \
        f"Unexpected vendor change: {relative}"
    checked += 1

text = (source / "devices/mhi_netdev_quectel.c").read_text()
assert not re.search(r"^\s*#\s*define\s+CONFIG_USE_RMNET_DATA_FOR_SKIP_MEMCPY\b",
                     text, re.MULTILINE), "Legacy rmnet_data path is enabled"
assert not re.search(r"^\s*#\s*define\s+CONFIG_QCA_NSS_DRV\b", text, re.MULTILINE)
assert "#include <rmnet_nss.h>" in text
assert "extern struct rmnet_nss_cb *rmnet_nss_callbacks" in text
for callback in ("nss_create(qmap_net)", "nss_free(qmap_net)", "nss_tx(skb)"):
    assert callback in text, f"Missing NSS callback: {callback}"
code = re.sub(r"/\*.*?\*/|//[^\n]*", "", text, flags=re.DOTALL)
assert "hrtimer_init(" not in code and "hrtimer_setup(" not in code
assert 'PCIE_MHI_DRIVER_VERSION "V1.6.0"' in (source / "core/mhi.h").read_text()
assert "0x0309" in (source / "controllers/mhi_qti.c").read_text()
assert "mhi_cntrl->klog_lvl = MHI_MSG_LVL_ERROR;" in (source / "core/mhi_init.c").read_text()
assert "static int uci_msg_lvl = MHI_MSG_LVL_ERROR;" in (source / "devices/mhi_uci.c").read_text()

package = (args.package / "Makefile").read_text()
for requirement in ("PKG_VERSION:=1.6.0", "VARIANT:=plain", "VARIANT:=nss",
                    "ifeq ($(BUILD_VARIANT),nss)", "+kmod-rmnet-nss",
                    "-I$(STAGING_DIR)/usr/include/qca-nss-rmnet", "-DCONFIG_QCA_NSS_DRV"):
    assert requirement in package, f"Missing package requirement: {requirement}"
nss = package.split("define KernelPackage/pcie_mhi_nss\n", 1)[1].split("endef", 1)[0]
assert "AUTOLOAD" not in nss, "NSS startup order must remain board-owned"
assert "Wno-error" not in package
print(f"PASS: {checked} vendor files, NSS callbacks, quiet defaults, "
      "package variants, and source-only package trees")
