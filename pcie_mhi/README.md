# Quectel PCIe MHI 1.6.0

This package provides Quectel PCIe control ports and QMAP network interfaces.
It supports ordinary networking and an optional Qualcomm NSS variant.

## Use

Select one driver:

- `kmod-pcie_mhi`: ordinary networking, without NSS.
- `kmod-pcie_mhi_nss`: NSS networking, with `kmod-rmnet-nss`.

The NSS variant requires a compatible `qca-nss-drv` package and NSS firmware.
It supports OpenWrt `qualcommax/ipq807x` and `qualcommax/ipq50xx` targets.
With wwand, select `wwand-qmi` and `wwand-datapath-rmnet_nss_mhi`.

Do not load this driver alongside `mhi_pci_generic`.
Load `rmnet_nss` before `pcie_mhi` for NSS support.
The NSS variant has no automatic module loading.

Controller and UCI logging default to errors and critical messages.
The UCI parameter `uci_msg_lvl=0` enables verbose UCI logging.

## Source and license

Source: [Quectel PCIe MHI 1.6.0 archive](https://www.quectel.com/content/uploads/2026/09/Quectel_Linux_PCIE_MHI_Driver_V1.6_EN.zip).
Archive SHA256: `1ba81ad4aaf746bdcb4807c916cf281e398a410dade4d664587ebeb67f4b1a93`.

Vendor copyright notices remain in the source. See `LICENSE` for GPL version 2.
