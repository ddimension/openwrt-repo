# pcie_mhi — Quectel PCIe/MHI host driver (Kernel 6.18 port)

Base: ChaingTsung/Quectel_MHI (Quectel_Linux_PCIE_MHI_Driver V1.3.8), has
SDX7X/0x0309 (RG650E). Ported to kernel 6.18 (qualcommax/ipq60xx):
- `src/Makefile`: `-Wno-missing-prototypes -Wno-error`
- `src/devices/mhi_netdev_quectel.c`: `hrtimer_init`->`hrtimer_setup` (>=6.15)

Status (2026-08-10): builds + loads + binds RG650E (17cb:0309) as `mhi_q`,
reaches MHI READY. BUT the RG650E over PCIe does NOT complete the MHI M0
handshake (modem emits no MSI; MHI-EP stays state 0) — same as in-tree
mhi_pci_generic. Blocker is modem-firmware-side, not this driver.
See chateau_5g notes/24. Newer base: FUjr/QModem V1.4 (already 6.18-ready).

Blacklist in-tree mhi to use this: rmmod mhi_pci_generic mhi (+clients) first.
