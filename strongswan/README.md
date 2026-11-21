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
- `ext-aka` (patches/1000-ext-aka-plugin.patch, new): an EAP-AKA card that
  runs the algorithm in an external program,
  `charon.plugins.ext-aka.program` (default `/usr/libexec/strongswan/ext-aka`):
  `<program> aka <identity> <RAND hex> <AUTN hex>` prints `RES`, `CK`, `IK`
  (one per line, hex) or `AUTS` on a synchronisation failure, and exits 0.
  wwand-ims-vowifi installs that program; it reaches the USIM in the modem
  over wwand's APDU channel;
- all of them in `strongswan-full` as well.

`eap-aka` alone authenticates nothing: it needs a card or a provider.
`ext-aka` is the card for a USIM elsewhere; `eap-aka-3gpp` is the software
one (K/OPc in the configuration), useful for tests only.

`PKG_RELEASE` is upstream's + 100, so apk on a device that has both feeds
takes this build. The image builds force this feed's copy
(`.github/ci/build-images.sh`, `FEED_OVERRIDES`).

The changes are meant for a pull request to openwrt/packages; once that is
merged (and in the release branches the images use), this copy goes.
