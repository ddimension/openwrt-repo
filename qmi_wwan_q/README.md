# Quectel qmi_wwan_q 1.5.0

Quectel's vendor USB QMI WWAN driver. Each QMAP channel is its own netdev
(`wwan0_1` .. `wwan0_<qmap_mode>`), and the driver registers them itself at
probe. With wwand, the `wwand-datapath-rmnet_nss` add-on adopts those
children. The add-on is named for Qualcomm NSS boards, where this driver is
what hands the channels to the offload, but it works without NSS as well.

## Use

The package does **not** load the module at boot. It claims the same Quectel
ids as the stock `qmi_wwan`, and with both loaded the first to bind takes the
modem. To move a modem over:

```sh
/etc/init.d/wwand stop
echo <usb interface, e.g. 2-1:1.4> > /sys/bus/usb/drivers/qmi_wwan/unbind
insmod qmi_wwan_q qmap_mode=2      # one channel per interface wwand muxes
/etc/init.d/wwand start
```

And back: `rmmod qmi_wwan_q`, then write the interface to
`/sys/bus/usb/drivers/qmi_wwan/bind`. On the RG502Q-EA the modem then needed a
`ubus call wwand modem_reset` before usbnet transmitted again (tx_errors,
nothing received; HW-observed on the ZyXEL NR7101, 2026-11-05).

`qmap_mode` is read at probe and fixed until the module is reloaded. The
compiled-in default is `CONFIG_QMI_WWAN_Q_QMAP_MODE` (2).

Built without the driver's NSS hooks. This feed's builds of it are for test
setups without NSS (the NR7101 image).

## Source and license

From [XT-Martinez/aw1000-feed](https://github.com/XT-Martinez/aw1000-feed)
`a7e14ad`, `wwan/qmi_wwan_q`, which takes Quectel's V1.5.0 from
[FUjr/QModem](https://github.com/FUjr/QModem) `c49654e`
(`driver/quectel_QMI_WWAN`). That copy carries the Linux 6.17+ usbnet changes.
Vendor copyright notices remain in the source; GPL version 2, see
`src/License.txt`.
