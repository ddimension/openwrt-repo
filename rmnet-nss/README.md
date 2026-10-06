# RMNET support for Qualcomm NSS

This module connects vendor QMAP interfaces to the Qualcomm NSS data path.
It exports the `rmnet_nss_callbacks` interface for the Quectel drivers.
It is separate from the standard Linux `rmnet` driver.

## History

The source credits The Linux Foundation (2019–2021) and Qualcomm Innovation Center (2022).
This import uses QModem commit `df51f56f707b8ac1443f48ffc1aaf7204f75c1d8`.
The C and header files match the qosmio `NSS-12.5-K6.x-wwan` branch.
The package retains QModem's `ccflags-y` build fix.

## Use

Select `kmod-rmnet-nss` in a compatible Qualcomm NSS build.
The package selects `kmod-qca-nss-drv` and its RMNET and C2C support.
It installs the callback header for driver compilation.
Load `rmnet_nss` before the vendor modem driver.

## Tests

On Cudy P5 with an RM551E-GL, this package carries live PCIe modem traffic.
The test configuration uses Quectel MHI 1.6.0, wwand, Linux 6.18.54, and NSS firmware 12.2.
IPv4 and IPv6 traffic work, and NSS RMNET receive counters increase.
The current feed packaging runs in the latest successful P5 test image.

The original source notices remain unchanged. See `LICENSE` for GPL version 2.
