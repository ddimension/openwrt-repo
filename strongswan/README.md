# strongswan (ddimension)

The strongSwan package of openwrt/packages (`net/strongswan`, master
42e2ff5, 6.0.7-r13, imported unchanged in this feed's history), with what
VoWiFi on a router needs and the packages feed does not build:

- the EAP-AKA plugins `eap-aka`, `eap-aka-3gpp`, `eap-simaka-pseudonym`,
  `eap-simaka-reauth`, and `strongswan-libsimaka`, the library they link
  against; `eap-aka` depends on `fips-prf` (libsimaka's PRF, without it
  charon has no EAP-AKA method);
- `p-cscf`, the RFC 7651 P-CSCF address request in IKEv2 (the ePDG hands
  out the IMS P-CSCF that way, TS 24.302);
- `Build/InstallDev`: the headers of libstrongswan, libcharon and libsimaka
  and this build's `config.h` under `/usr/include/strongswan`, libsimaka
  under `/usr/lib/ipsec`, for charon plugins built OUT of this tree.
  wwand-ims builds its two that way (its `src/strongswan`, packaged there as
  `strongswan-mod-ext-aka` and `strongswan-mod-epdg-idr`, pinned to this
  version and release): `ext-aka`, an EAP-AKA card running the AKA in an
  external program, and `epdg-idr`, accepting an ePDG's own IDr. They were
  patches here (1000, 1001) until 6.0.7-r118; bump wwand-ims's `SW_ABI`
  with this package's version or release;
- all of them (but the two of wwand-ims) in `strongswan-full` as well.

`eap-aka` alone authenticates nothing: it needs a card or a provider.
`ext-aka` (wwand-ims) is the card for a USIM elsewhere; `eap-aka-3gpp` is the software
one (K/OPc in the configuration), useful for tests only.

`PKG_RELEASE` is upstream's + 100, so apk on a device that has both feeds
takes this build. The image builds force this feed's copy
(`.github/ci/build-images.sh`, `FEED_OVERRIDES`).

The changes are meant for a pull request to openwrt/packages; once that is
merged (and in the release branches the images use), this copy goes.
