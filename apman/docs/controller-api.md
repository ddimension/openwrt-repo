# apman — controller API

Everything a WLAN controller needs to fully manage an OpenWrt access point
running `apman`. The agent is a thin, mostly generic bridge between the device's
ubus bus and an MQTT broker: it forwards ubus notifications and periodic state
to MQTT, and executes ubus calls received from MQTT. Almost every payload below
is the **verbatim ubus reply**, so the ubus sources stay the authority for field
level details.

* Package: `apman` (feed `ddimension/openwrt-repo`), daemon `/usr/bin/apman-status`
* Transport: MQTT 3.1.1 via lua-mosquitto, optional TLS
* Configuration: `/etc/config/apman`, see [README](../README.md)

## 1. Identity and topic layout

The device identity is `<hostname>`: `apman.main.hostname` if set, otherwise the
uci `system` hostname. It appears verbatim in every topic, so it must be unique
per broker and stable across reboots.

```
<topic_prefix>ap/<hostname>/...        per device (default prefix: apman/)
<topic_prefix>command                  fleet wide command topic
```

Conventions used below:

* **QoS/retain** — unless stated otherwise a publish is QoS 0, not retained.
* **What to subscribe with** — the periodic status is the bulk of the traffic and
  is replaced every `status_interval` anyway, so subscribe to it with QoS 0; a
  lost message costs nothing and QoS 1 only buys retransmission of data that is
  already stale. Subscribe with QoS 1 to everything that is not repeated:
  `command_result/#`, `properties/#`, `online`, `booted`. Overlapping
  subscriptions are fine — the broker delivers one copy at the highest matching
  QoS.
* **`timestamp`** — float, seconds since the epoch, taken on the device
  (`socket.gettime()`). Added to every payload that is a JSON object. Device
  clocks may be unsynchronised early after boot.
* Payloads are JSON. Numbers that cannot be represented (inf/nan) are encoded
  as `null`.

## 2. Lifecycle

| Phase | What the controller sees |
|---|---|
| Device connects | `online` = `{"status":"online","timestamp":…}` |
| First connect only | `booted` = `{}`, then the retained properties, then the first status |
| Every (re)connect | `online`, `properties/system/board` (retained), `properties/system/info` |
| Broker loses the device | Last will on `online`: `{"status":"offline"}`, QoS 1, **not retained** |

A controller must therefore be subscribed *before* the disconnect to observe the
last will; there is no retained offline marker to poll. Treat a missing status
update for more than a few `status_interval` periods as an additional liveness
signal.

While the device is disconnected, publishes are **dropped**, not queued. After a
reconnect the retained properties are republished, the periodic status resumes,
and the command subscriptions are re-established. Reconnects use exponential
backoff (2…120 s) with per host jitter.

The ubus subscriptions (and therefore `properties/hostapd/*` and
`properties/session/create`) are established once, on the first successful MQTT
connect, and again whenever the hostapd object list changes.

## 3. State and property topics

All relative to `<topic_prefix>ap/<hostname>/`.

### `properties/system/board` — retained, QoS 1
`ubus call system board`: `kernel`, `hostname`, `system`, `model`, `board_name`,
`rootfs_type`, `release{distribution,version,revision,target,description}`.
The controller's source for model and firmware version.

### `properties/system/info`
`ubus call system info`: `localtime`, `uptime`, `load[3]`,
`memory{total,free,shared,buffered,available,cached}`, `swap{total,free}`.
Published on every connect and on every status tick.

### `properties/hostapd/<ifname>/rrm_nr_get_own` — retained, QoS 1
`ubus call hostapd.<ifname> rrm_nr_get_own`: this BSS's own neighbour report
element, `{"value":["<bssid>","<ssid>","<hex nr element>"]}`. Collect these
across the fleet and push the relevant subset back to each AP with `rrm_nr_set`
to build 802.11k neighbour reports.

### `properties/hostapd/<ifname>/bss_info` — retained, QoS 1
`ubus call hostapd bss_info {"iface":"<ifname>"}`. Static BSS configuration:
`hw_mode`, `channel`, `ieee80211ac`, `ieee80211ax`, `bssid`, `ssid`, `wpa`,
`wpa_key_mgmt`, `wpa_pairwise`, `auth_algs`, `ieee80211w`,
`owe_transition_ifname`. **Requires the ucode based hostapd** (OpenWrt 23.05+);
absent otherwise.

### `properties/agent` — retained, QoS 1
Inventory of the agent itself, so a controller can gate features per AP instead
of guessing from firmware versions:

```json
{"agent":"apman","version":"56-2","hostname":"ap-av-attic","started":1786747171.6,
 "features":["command_v2","resend_suppression","bss_events","hostapd_status",
             "bss_info","netifd_notifications","ubus_events","station_dump",
             "survey","assoclist_device"],
 "hostapd":{"ucode":true},
 "intervals":{"status":10,"probe":10,"survey":300,
              "wireless_republish":60,"property_republish":300}}
```

Absence of this topic means an agent older than 56-2: no `command_v2`, no
`survey`, no `bss_info`, and probe requests are unthrottled.

### `survey/<ifname>`
`ubus call iwinfo survey`, published every `survey_interval` seconds (default
300, `0` disables). Per channel: `mhz`, `noise`, `active_time`, `busy_time`,
`busy_time_ext`, `rx_time`, `tx_time` — the input for fleet wide channel
planning. Busy ratio is `busy_time / active_time`.

### `properties/session/create`
The ubus rpc session apman created for remote access, `{"ubus_rpc_session":
"<32 hex chars>", …}`. The session is granted read/write/exec on `/*` and has no
timeout. Use it as the first element of a JSON-RPC `params` array, or against
the device's own `/ubus` endpoint if one is reachable. Republished whenever the
ubus subscriptions are rebuilt — the controller should always use the most
recent one.

## 3a. Resend suppression (important for consumers)

To keep the broker and the consumer from processing identical payloads over and
over, apman suppresses unchanged messages on the topics where the payload is
almost always the same:

| Topic | Rule | Option |
|---|---|---|
| `properties/hostapd/<dev>/rrm_nr_get_own`, `properties/hostapd/<dev>/bss_info` | Published when changed, otherwise at most every 300 s | `property_republish` |
| `wireless/status` | Published when changed, otherwise at most every 60 s | `wireless_republish` |
| `notifications/hostapd/<dev>/probe` | At most one per station per 10 s | `probe_interval` |

Consequences for a controller:

* **Do not use these topics as a heartbeat.** `online` (every `status_interval`)
  and `device/hostapd/<dev>/status` are the liveness signals; they are never
  suppressed.
* State is still guaranteed to converge: everything suppressed is either
  retained on the broker (properties) or republished within its interval, so a
  consumer that lost its state resyncs within `wireless_republish` seconds
  without any action.
* On every MQTT reconnect the suppression cache is cleared and all properties
  are published once, so a broker restart cannot leave a consumer stale.
* Setting any of the options to `0` disables the respective suppression.

Log volume on the AP is bounded the same way: command payloads are truncated to
`log_payload_len` characters (default 200, `0` logs them in full).

## 4. Periodic status

Published every `status_interval` seconds (default 10).

### `device/hostapd/<ifname>/status`
One message per master interface. VLAN slave interfaces (`Master (VLAN)` mode
whose name is prefixed by the master's) are folded into their master.

| Key | Source | Notes |
|---|---|---|
| `timestamp` | — | Time the payload was assembled |
| `info` | `iwinfo info {device}` | phy mode, channel, txpower, country, hwmode, htmode, signal, noise, bitrate, encryption, hardware |
| `clients` | `hostapd.<ifname> get_clients` | see below |
| `assoclist` | `iwinfo assoclist {device}` | `{"results":[…]}`, **merged across master and slaves** |
| `stations` | `iw dev <dev> station dump` | map `<mac>` → fields, see below. Raw text on agents older than 56-2 |
| `v` | — | payload version of this device object. `2` since apman 56-2, absent before |
| `status` | `network.device status {name}` | link state, MTU, `statistics{rx_bytes,tx_bytes,rx_packets,…}` |
| `ap_status` | `hostapd.<ifname> get_status` | see below |
| `hostapd_status` | `hostapd status` → `interfaces[<ifname>]` | see below, ucode hostapd only |

`clients` is `{"freq":…,"clients":{"<mac>":{…}}}`, per station:

* flags `auth`, `assoc`, `authorized`, `preauth`, `wds`, `wmm`, `ht`, `vht`,
  `he`, `wps`, `mfp`, plus `mbo` when built with MBO
* `aid`, `rrm[5]`, `extended_capabilities[]`
* `bytes{rx,tx}`, `packets{rx,tx}`, `airtime{rx,tx}`, `rate{rx,tx}` (kbit/s),
  `signal` (dBm) — these come from the driver and are the cheapest per client
  counters available
* `signature` — client taxonomy fingerprint, only with `CONFIG_TAXONOMY`

`ap_status` is `hostapd get_status`: `driver`, `status` (hostapd state, e.g.
`ENABLED`), `bssid`, `ssid`, `freq`, `channel`, `op_class`, `beacon_interval`,
`bss_color` (−1 when disabled), `phy`, plus

* `airtime{time,time_busy,utilization}` — utilization is 0…255
* `dfs{cac_seconds,cac_seconds_left,cac_active}`
* `rrm{neighbor_report_tx}`
* `wnm{bss_transition_query_rx,bss_transition_request_tx,bss_transition_response_rx}`

The `rrm`/`wnm` counters are monotonic per hostapd run and are the direct
measure of 802.11k/v steering activity.

`assoclist` entries are the rpcd iwinfo plugin's verbatim output (`mac`,
`signal`, `signal_avg`, `noise`, `inactive`, `connected_time`, `thr`,
`authorized`, `authenticated`, `rx{…}`, `tx{…}` with rate/mcs/nss/mhz/he flags),
extended by apman with:

* **`device`** — the interface the station was seen on. For a plain BSS this is
  the master; for `Master (VLAN)` setups it distinguishes the slave interfaces.
  Stations of slave interfaces appear in the master's `assoclist` since
  apman 56-2; before that they were only visible in the `stations` text.

`stations` covers interfaces that never appear in `assoclist` (p2p, mesh peers),
which is why it is kept in addition to `assoclist`. Interfaces without a single
associated station are dumped as well and yield `{}` — absence of the key means
the dump failed, an empty object means the interface is idle.

**Payload version 2 (apman ≥ 56-2)** — `stations` is a map, not text:

```json
"v": 2,
"stations": {
  "1c:bf:ce:ea:1a:6e": {
    "device": "wap-knet1",
    "signal": "-70 dBm", "signal_avg": "-70 dBm",
    "tx_bitrate": "702.0 MBit/s VHT-MCS 8 80MHz VHT-NSS 2",
    "connected_time": "132239 seconds", "inactive_time": "3330 ms",
    "authorized": "yes", "authenticated": "yes", "associated": "yes"
  }
}
```

The agent parses `iw station dump` itself. The controller used to do this on
every message for the whole fleet; on the device it happens once per interval
and the work spreads across the access points.

* Keys are the labels `iw` prints, lowercased where `iw` does, with ` `, `,`,
  `.`, `-` and `/` replaced by `_` — the same normalisation the controller
  applied before, so field names downstream are unchanged. `iw`'s own
  capitalisation survives (`MFP`, `WMM_WME`, `DTIM_period`, `TDLS_peer`), and
  one label keeps its brackets: `associated_at_[boottime]`.
* **Values stay strings, units included** (`"-70 dBm"`, `"3330 ms"`,
  `"702.0 MBit/s VHT-MCS 8 80MHz VHT-NSS 2"`). Nothing is converted, so no
  information is lost and no parsing decision is baked into the agent. Consumers
  that want numbers must strip the unit.
* `device` is added per station: the interface it was actually seen on, which is
  what distinguishes the slaves of a `Master (VLAN)` setup after the dumps of
  master and slaves have been merged.
* The MAC key is lowercase.

Detect the form, never assume it: `v == 2` (or `stations` being an object rather
than a string) means structured. A controller that must serve both can keep its
old text parser for payloads without `v`.

### `hostapd/status`
`ubus call hostapd status`, the authoritative BSS topology:

```json
{"interfaces": {
   "wlan0": {"wiphy":"phy0","macaddr":"…","running":true,"pending":false,"radio":0},
   "wlan1": {"wiphy":"phy1","macaddr":"…","links":{"0":{"radio":0,"macaddr":"…","running":true,"pending":false}}}
 },
 "timestamp": …}
```

`links` is present for MLO/Wi-Fi 7 multi-link BSSes and is the only place the
per-link MAC addresses are exposed. Requires the ucode based hostapd; disable
the query with `option hostapd_status '0'`.

### `wireless/status`
`ubus call network.wireless status`: per radio `up`, `pending`, `autostart`,
`disabled`, `retry_setup_failed`, `config{…}` and `interfaces[]` with
`section`, `ifname`, `config{mode,ssid,encryption,…}`. This is the uci view;
`hostapd/status` is the runtime view.

## 5. Notifications

Forwarded verbatim, with `timestamp` added. One MQTT message per ubus
notification.

### `notifications/hostapd/<ifname>/<method>`
Every ubus object whose name starts with `hostapd` is subscribed, so the topic
segment is the object name with the `hostapd.` prefix stripped
(`hostapd.wlan0` → `wlan0`, `hostapd-auth` → `auth`, the global `hostapd`
object → `hostapd`).

| `<method>` | Payload | Meaning |
|---|---|---|
| `probe` | `address`, `ifname`, `target`, `signal`, `freq`, `ht_capabilities{…}`, `vht_capabilities{…}` | Probe request. High volume — consider filtering on the controller |
| `auth` | as above | Authentication attempt |
| `assoc` | as above | Association attempt |
| `sta-authorized` | `address`, `ifname` | Station finished 4-way handshake — the "client is online" event |
| `disassoc` | `address`, `ifname` | Station disassociated |
| `deauth` | `address`, `ifname` | Station deauthenticated |
| `local-deauth` | `address`, `ifname` | AP initiated deauth (e.g. `del_client`) |
| `inactive-deauth` | `address`, `ifname` | Kicked for inactivity |
| `key-mismatch` | `address`, `ifname` | PSK mismatch — wrong password |
| `beacon-report` | `address`, `bssid`, `report{…}` | Answer to `rrm_beacon_req` |
| `link-measurement-report` | `address`, `dialog-token`, `rx-antenna-id`, `tx-antenna-id`, `rcpi`, `rsni` | Answer to `link_measurement_req` |
| `bss-transition-query` | `address`, `dialog-token`, `reason`, candidate list | Client asks where to roam (11v) |
| `bss-transition-response` | `address`, `dialog-token`, `status-code`, `bss-termination-delay`, `target-bssid`, candidate list | Client's answer to a steering request |
| `channel-switch` | `ifname`, `freq`, `bssid` | CSA completed |
| `radar-detected` | `frequency`, `width`, `center1`, `center2` | DFS radar event |
| `apup-newpeer` | `address`, `ifname` | APuP micro peering |
| `bss.add` / `bss.remove` | `name` | BSS appeared/disappeared (global `hostapd` object) |
| `bss.reload` | `name`, `reconf` | BSS reconfigured |

`probe`, `auth` and `assoc` are notifications hostapd *waits on* — a subscriber
that answers them can reject a client. apman cannot: the Lua ubus binding calls
subscriber callbacks with no return path (`ubus/lua/ubus.c`, `lua_call(state, 2,
0)`, no `ubus_send_reply`). The same limitation applies to the `hostapd-auth`
object's `sta_auth`/`sta_connected` notifications, which would otherwise allow
central authorisation. Implementing that requires a patched binding or a
separate ucode/C helper.

`bss.*` also drives apman itself: on such a notification it rebuilds its ubus
subscriptions after `ubus_settle` seconds, and the object-list poll drops to
`ubus_check_interval_slow` (30 s) as a safety net.

### `notifications/hostapd/<ifname>/ctrl/<EVENT>` (agent ≥ 56-7)

The agent keeps a permanent `ATTACH` on the control socket of every bss and
forwards hostapd's own event stream. This is not a second copy of the ubus
notifications — the two barely overlap:

| | ubus notifications | control channel |
|---|---|---|
| volume, measured over 240 s on a busy ap | 171 (168 of them probe requests) | 4 |
| probe / auth / assoc / disassoc | yes, decoded | not delivered at all |
| why a station was refused | — | `AP-REJECTED-MAX-STA`, `AP-REJECTED-BLOCKED-STA`, `AP-STA-POSSIBLE-PSK-MISMATCH` |
| eap server verdict | — | `CTRL-EVENT-EAP-SUCCESS2` / `-FAILURE2` / `-TIMEOUT-FAILURE2` |
| identity of a station | — | `AP-STA-CONNECTED` carries `keyid`, `vlanid`, `ip_addr` |
| steering answer | `status-code` arrives as a **boolean** | `BSS-TM-RESP` prints `status_code=%u` |
| channel life cycle | radar and the finished switch | `ACS-*`, `DFS-CAC-*`, `DFS-NEW-CHANNEL`, `AP-CSA-FINISHED`, `CTRL-EVENT-STARTED-CHANNEL-SWITCH` |
| bss state | — | `AP-ENABLED`, `AP-DISABLED`, `INTERFACE-ENABLED/DISABLED` |

Because probe requests do not travel this way, the stream stays quiet and needs
no throttling.

```json
{"event":"AP-STA-CONNECTED","ifname":"wap-knet0","address":"e2:9e:3f:09:7e:90",
 "fields":{"auth_alg":"open","keyid":"17-anna","vlanid":"7"},
 "priority":3,"raw":"AP-STA-CONNECTED e2:9e:… auth_alg=open keyid=17-anna",
 "timestamp":1786907209.2}
```

`address` is the station of the event when the line carries one, `fields` the
`key=value` pairs, `raw` the line as hostapd wrote it minus the syslog priority.

Only allowlisted events are forwarded — stations, refusals, steering, eap,
channel and bss life cycle, opmode changes, measurements, wps. `BEACON-RESP-RX`
is deliberately not among them: the ubus `beacon-report` notification carries
the same measurement already decoded. Adjust with `list ctrl_event_allow` /
`list ctrl_event_deny`, or take everything with `option ctrl_event_all 1`.

Two consequences worth knowing:

* hostapd forgets its monitors when it restarts. The agent reattaches from the
  same bss list that drives the ubus subscriptions, so a `bss.reload` repairs it
  within the settle delay.
* An answer can arrive here that the synchronous ubus path missed — observed
  with a transition response that the command channel timed out on while
  `BSS-TM-RESP` still came through.

### `notifications/network/interface/<method>` and `notifications/network/device/<method>`
netifd's ubus notifications, subscribed via `list subscribe` (default: both).

| Object | `<method>` | Payload |
|---|---|---|
| `network.interface` | `interface.update`, `interface.down` | `interface` plus the full interface status dump |
| `network.device` | `add`, `remove`, `up`, `down`, `link_up`, `link_down`, `setup`, `teardown`, `auth_up`, `topo_change`, `vlan_update`, `update_ifname`, `update_ifindex` | `name`, `present`, `active`, `link_active`, `auth_status` |

These make uplink and port state event driven instead of polled. Add further
objects with `list subscribe '<object>'`; unknown objects are skipped with a log
line, so a controller cannot rely on a topic existing without checking.

### `events/<event>`
ubus **broadcast** events (`ubus listen`), configured with `list listen_event`.
Default: `network.interface` → topic `events/network/interface`, payload
`{"action":"ifup"|"ifdown","interface":"<name>","event":"network.interface",
"timestamp":…}`.

Only exact event names work: the Lua binding does not pass the event name to the
handler, so apman has to derive it from the registration — wildcard patterns
would be ambiguous and are not supported.

## 6. Command channel

apman subscribes (QoS 1):

| Topic | Handler |
|---|---|
| `<topic_prefix>command` | Fleet wide broadcast, single command. Disable with `option command_topic_global '0'` |
| `<topic_prefix>ap/<hostname>/command` | Single command for this device |
| `<topic_prefix>ap/<hostname>/command/bulk` | List of commands for this device |

### Single command

```json
{"jsonrpc":"2.0","id":42,"method":"call",
 "params":["<session>","<ubus object>","<ubus method>",{"<arg>":"<value>"}]}
```

`params` follows the OpenWrt ubus JSON-RPC convention. The first element (the
session id) is **ignored** by apman — it calls ubus locally as root. Send the
session from `properties/session/create` or an empty string.

Requirements, otherwise the message is silently discarded (with a log line):
`jsonrpc` == `"2.0"`, `method` == `"call"`, `params` is an array.

The response is published **QoS 1, not retained** (it was retained up to agent
56-1) to `<topic_prefix>ap/<hostname>/command_result`:

```json
{"jsonrpc":"2.0","id":42,"result":{…ubus reply…}}
```

A command sent to the fleet wide topic is answered by every device on its own
`command_result` topic.

### hostapd control channel (`method: "ctrl"`, agent ≥ 56-3)

hostapd listens on a unix datagram socket per bss even while the ubus interface
is up; the two are independent and several clients may talk at once. The agent
proxies it, because a few things have no ubus equivalent:

| | |
|---|---|
| `RELOAD_WPA_PSK` | reloads `wpa_psk_file` **without touching associations**. ubus only offers `reload`, which restarts the bss and drops every client |
| `WPS_PIN <uuid\|any> <pin> [timeout]` | ubus `wps_start` is pushbutton only |
| `BSS_TM_REQ` | the response event reports `status_code=<n>` as text, so the reject reason survives — over ubus it is a `blobmsg_add_u8` that libubox renders as a boolean |
| `MIB` | `dot11RSNA4WayHandshakeFailures`, RADIUS client counters (server address, round trip time, accepts, rejects, timeouts) |
| `STA <mac>` | `AKMSuiteSelector` and `dot11RSNAStatsSelectedPairwiseCipher` (what the client actually negotiated), `hostapdWPAPTKState`, `capability`, `listen_interval`, `supported_rates`, `timeout_next` |
| `GET_CONFIG` | the **running** bss config (`wpa`, `key_mgmt`, ciphers), not the file on disk |

```json
{"jsonrpc":"2.0","id":42,"method":"ctrl","params":["","<ifname>","GET_CONFIG"]}
```

The answer arrives on the usual result topics:

```json
{"jsonrpc":"2.0","id":42,"ubus_status":0,"result":{
   "raw":"bssid=…\nssid=kalnet\nwpa=2\n…",
   "values":{"bssid":"…","ssid":"kalnet","wpa":"2"},
   "lines":["bssid=…","ssid=kalnet","wpa=2"]}}
```

`raw` is the verbatim reply, `values` the `key=value` lines parsed, `lines`
every line in order (a station dump starts with a bare address line).

Notes for a controller:

* The request is asynchronous — the agent does not block on it, and a bulk
  batch containing `ctrl` entries is published once the last answer is in.
  Every request carries its own deadline (`ctrl_timeout`, default 3 s) and
  fails with code 7 rather than hanging.
* Only allowlisted commands are accepted; anything else comes back as code 6.
  The list covers the reading commands plus `RELOAD_WPA_PSK`, `BSS_TM_REQ`,
  `WPS_PIN`/`WPS_PBC`, `REQ_BEACON` and `REQ_LINK_MEASUREMENT`. `DISASSOCIATE`
  and the ACL modifications are deliberately not in it. Extend with
  `list ctrl_allow`, or lift it entirely with `option ctrl_allow_all 1`.
* Use the interface name (`wap-knet1`), not the ubus object name. `global`
  addresses hostapd itself.
* Code 4 means there is no control socket for that interface, code 8 that the
  proxy is switched off or luasocket has no unix socket support — check
  `ctrl_proxy` in `properties/agent` first.

**Before `RELOAD_WPA_PSK`**: hostapd re-reads the file its *running* config
points at. Write the psk file first, and make sure the uci `wifi-station`
sections produce the same content — otherwise the next `wifi reload`
regenerates the file from uci and silently reverts what was just distributed.

### Bulk command

```json
{"list":[ {"jsonrpc":"2.0","id":1,"method":"call","params":[…]},
          {"jsonrpc":"2.0","id":2,"method":"call","params":[…]} ]}
```

Executed in order, the responses are published as a JSON array (same order) to
`command_result/bulk`, retained, QoS 1. Up to agent 56-1 a single entry failing
validation aborted the **whole batch with nothing published**; since 56-2 every
entry produces its own result or error object at its position in the array. A
payload without a `list` array yields one error object on the same topic.

Bulk is the cheaper way to address several interfaces of one access point: one
message, one round trip, the answers arrive together.

### Error semantics (command channel v2, agent >= 56-2)

Every request produces a response, and success is distinguishable from failure:

```json
{"jsonrpc":"2.0","id":42,"result":{...},"ubus_status":0,"ts":1786747200.1}
{"jsonrpc":"2.0","id":42,"error":{"code":4,"message":"not found",
                                  "object":"hostapd.wlan9","method":"rrm_nr_set"},
 "ts":1786747200.1}
```

`ubus_status: 0` marks a successful call even when `result` is absent — several
ubus methods legitimately return nothing (`rrm_nr_set`), which older agents made
indistinguishable from a failure. `code` is the ubus status (2 invalid argument,
3 method not found, 4 not found, 6 permission denied, 7 timeout, 8 not
supported).

Responses are additionally published to **`command_result/<id>`**, which is the
topic a controller should wait on: the shared topic carries whichever answer was
produced last, so two commands in flight overwrite each other there. `<id>` is
the request id stripped of everything outside `[A-Za-z0-9._-]`, so keep ids
within that set if you want to subscribe to a single one.

Neither topic is retained since 56-2. A retained result was handed to every
reconnecting consumer and read as the answer to the command it had just sent —
the controller has to match on `id` regardless, but with retain it matched an id
from the previous session. Two consequences for a controller:

* Do not send a command before the subscription to its result topic is
  established; there is no retained copy to fall back on.
* Use a fresh, unique `id` per command. A deterministic id combined with a
  caching consumer returns the previous run's answer instantly.

Malformed requests now also produce an error response instead of being dropped
silently, and in a bulk batch a bad entry no longer discards the whole batch —
each entry gets its own result or error, in order.

The one exception is `command_result/bulk`, which is **still retained** — the
array is published under a single topic without per-id copies, so the `id` match
inside the array is the only correlation there and a stale retained array can
still be seen once on subscribe.

A crashing call still takes the daemon down; procd restarts it after ~10 s.

## 7. Controller cookbook

All of these are plain ubus calls sent through the command channel.

**Client steering (802.11v)** — `hostapd.<ifname>` `bss_transition_request`
with `addr`, `disassociation_imminent`, `disassociation_timer`, `validity_period`,
`neighbors` (list of neighbour report elements), `abridged`, `dialog_token`.
The client's answer arrives as a `bss-transition-response` notification.

**Neighbour reports (802.11k)** — collect `rrm_nr_get_own` from every AP, then
`rrm_nr_set` with `list` = `[[bssid, ssid, nr], …]` on each AP.
`rrm_nr_list` reads back what is configured.

**Measurements** — `rrm_beacon_req` (`addr`, `op_class`, `channel`, `duration`,
`mode`, `bssid`, `ssid`) → `beacon-report`; `link_measurement_req` (`addr`) →
`link-measurement-report`.

**Disconnect / ban** — `del_client` with `addr`, `reason`, `deauth` (bool),
`ban_time` (ms). `list_bans` shows the active bans.

**Channel / power** — `switch_chan` (`freq`, `bcn_count`, `sec_channel_offset`,
`center_freq1`, `bandwidth`, `ht`, `vht`, `he`) on `hostapd.<ifname>`, or
`switch_channel` on the global `hostapd` object. `update_beacon` after changing
beacon contents, `set_vendor_elements` for custom IEs.

**Airtime policy** — `update_airtime` with per station weights.

**Configuration** — `uci` (`get`, `set`, `add`, `delete`, `commit`) plus
`ubus call network reload` / `ubus call network.wireless up`. The global
`hostapd` object also offers `config_add`, `config_set`, `config_remove`,
`config_reset`, `reload` for direct hostapd config handling.

**Files, packages, logs** — `file` (`read`, `write`, `exec`, `list`, `stat`) via
rpcd, `system` (`reboot`), `log` (`read`, `write`). `file exec` is how a
controller runs `sysupgrade`, `logread`, `iw`, etc.

**Interfaces** — `network.interface.<name>` `up`/`down`/`status`,
`network.device status`, `network reload`.

## 8. Feature detection

| Feature | Requires | Detect via |
|---|---|---|
| `hostapd/status`, `properties/…/bss_info`, `bss.*` notifications | ucode based hostapd (OpenWrt 23.05+) | topic present / `hostapd` in `ubus list` |
| `rrm`/`wnm` counters in `ap_status` | OpenWrt patch `590-rrm-wnm-statistics` | keys present |
| `signature` per client | hostapd built with `CONFIG_TAXONOMY` | key present |
| `mbo` per client | hostapd built with `CONFIG_MBO` | key present |
| `assoclist[].device`, slave stations in `assoclist` | apman ≥ 56-2 | key present |
| structured `stations` map | apman ≥ 56-2 | `v == 2` in the status payload |
| `error{code,message,object,method}`, `ubus_status`, `command_result/<id>` | apman ≥ 56-2 | `properties/agent` `features[]` |
| `properties/agent`, `survey/<ifname>` | apman ≥ 56-2 | retained topic present |
| `mib`, `sta_ctrl` in the status payload | apman ≥ 56-4 | `properties/agent` `features[]` |
| `keyid` per station (iPSK identity) | apman ≥ 56-5 | key present in `sta_ctrl` |
| `notifications/hostapd/<ifname>/ctrl/<EVENT>` | apman ≥ 56-7 | `ctrl_events` in `properties/agent` |
| `apup-newpeer` | OpenWrt patch `780-Implement-APuP` | notification arrives |

Do not assume a topic exists because the device is online — an AP with no
hostapd instance publishes no `device/hostapd/*` at all, and apman waits for the
first hostapd object before it establishes any subscription.

## 9. Limitations

* No reply path from notifications, so no central authorisation or probe
  filtering (see §5).
* No queueing while offline: everything except the retained properties is lost
  during a broker outage.
* Commands are executed as root without authorisation checks. The broker is the
  only security boundary — see the security section of the [README](../README.md).
* `command_result/bulk` is still retained, so a controller sees the last batch of
  the previous session on subscribe; always match `id`.
* `timestamp` is device local and unsynchronised right after boot.
