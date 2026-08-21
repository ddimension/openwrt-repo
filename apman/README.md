# apman

AP management and statistics for OpenWrt access points.

Two entry points share one Lua module (`/usr/lib/lua/apman.lua`):

* **`apman-status`** (procd service) — a ubus↔MQTT bridge: subscribes to every
  `hostapd.*` ubus object, publishes their notifications and a periodic full
  status snapshot, and executes JSON-RPC commands received from the broker.
* **`apman-collectd.lua`** (collectd lua plugin) — dispatches airtime, DFS,
  channel, station count and interface counters per hostapd device and
  aggregated per radio, using the extra types in
  `/usr/share/collectd/types.apman.db`.

## Configuration (`/etc/config/apman`, section `main`)

| Option | Default | Meaning |
|---|---|---|
| `enabled` | `0` | Master switch, checked by the init script and the daemon |
| `hostname` | uci `system` hostname | Identity used in every topic |
| `mqtt_host` | built-in default | Broker address |
| `mqtt_port`, `mqtt_keepalive` | libmosquitto defaults | Broker connection |
| `mqtt_clientid` | hostname | MQTT client id |
| `mqtt_username`, `mqtt_password` | — | Broker credentials |
| `cafile`, `capath`, `certfile`, `keyfile`, `cert`, `tls_version`, `ciphers`, `tls_insecure` | — | TLS setup, passed to lua-mosquitto |
| `topic_prefix` | `apman/` | Topic namespace, a trailing `/` is added when missing |
| `status_interval` | `10` | Seconds between full status publishes |
| `station_dump` | `1` | Publish the raw `iw dev <dev> station dump` text |
| `command_topic_global` | `1` | Also subscribe the fleet-wide command topic |
| `hostapd_status` | `1` | Publish the global hostapd status (bss/radio/MLD topology) |
| `subscribe` (list) | `network.interface`, `network.device` | Extra ubus objects whose notifications are forwarded |
| `listen_event` (list) | `network.interface` | ubus broadcast events that are forwarded |
| `property_republish` | `300` | Seconds after which an unchanged retained property is republished |
| `wireless_republish` | `60` | Seconds after which an unchanged `wireless/status` is republished |
| `probe_interval` | `10` | Minimum seconds between forwarded probe requests per station |
| `log_payload_len` | `200` | Characters of a command payload written to the log, `0` = full |
| `ubus_check_interval` | `1` | Seconds between hostapd object list checks |
| `ubus_check_interval_slow` | `30` | Poll interval once hostapd delivers `bss.*` notifications |
| `ubus_settle` | `5` | Seconds to wait after an object list change before resubscribing |
| `mqtt_loop_interval` | `200` | Milliseconds between mosquitto loop ticks |
| `mqtt_retry_min` / `mqtt_retry_max` | `2` / `120` | Reconnect backoff bounds in seconds |
| `radius_enabled` | `0` | Run the minimal RADIUS server for hostapd per station PSK queries |
| `radius_port` | `1812` | UDP port the server binds |
| `radius_secret` | — | Shared secret, must match hostapd's `auth_server_shared_secret`; without it the server stays off |
| `radius_wifi_config` | `/etc/config/wireless` | Config file the keys are read from (the `wifi-station` sections) |
| `radius_reload_interval` | `10` | Seconds between config change checks, `0` = only on ubus notifications |

Reconnects use exponential backoff with per-host jitter (the RNG is seeded from
the hostname), so a fleet does not hammer the broker in lockstep after an
outage. Nothing in the daemon blocks the uloop: connecting, reconnecting and
waiting for hostapd to appear are all timer driven.

## Topics

**The full contract for a WLAN controller — every topic, payload, notification
and command — is in [docs/controller-api.md](docs/controller-api.md).** Short
version, all below `<topic_prefix>ap/<hostname>/`:

| Topic | Retained | Content |
|---|---|---|
| `online` | no | `{"status":"online"}` / last will `{"status":"offline"}` |
| `booted` | no | Sent once after the first successful connect |
| `properties/system/board` | yes | `ubus call system board` |
| `properties/system/info` | no | `ubus call system info` |
| `properties/hostapd/<dev>/rrm_nr_get_own` | yes | Neighbour report element |
| `properties/hostapd/<dev>/bss_info` | yes | Static BSS config (ucode hostapd only) |
| `properties/session/create` | no | ubus rpc session for remote access |
| `notifications/hostapd/<dev>/<method>` | no | Raw hostapd ubus notifications |
| `notifications/network/interface/<method>` | no | netifd interface notifications |
| `notifications/network/device/<method>` | no | netifd device notifications |
| `events/<event>` | no | Forwarded ubus broadcast events |
| `device/hostapd/<dev>/status` | no | info, clients, assoclist, stations, device and ap status |
| `hostapd/status` | no | BSS/radio/MLD topology (ucode hostapd only) |
| `wireless/status` | no | `ubus call network.wireless status` |
| `command`, `command/bulk` | — | Subscribed; JSON-RPC requests |
| `command_result`, `command_result/bulk` | yes | JSON-RPC responses |

`<topic_prefix>command` (without the `ap/<hostname>/` part) is a fleet-wide
broadcast command topic; disable it per device with `command_topic_global '0'`.

In `device/hostapd/<dev>/status`, `assoclist` holds the master interface and,
for `Master (VLAN)` setups, the stations of its slave interfaces as well; every
entry carries a `device` field naming the interface it was seen on.

## RADIUS server for per station PSKs

With `radius_enabled '1'` the agent runs a minimal RADIUS server on udp/1812.
It speaks exactly the contract hostapd uses for `wpa_psk_radius` (1/2/3) and
`sae_password_psk`: an Access-Request with the station MAC as User-Name is
answered with Access-Accept carrying the PSK in an encrypted Tunnel-Password
attribute, or Access-Reject. Every packet must carry a valid
Message-Authenticator — anything else is dropped without an answer. Point
hostapd's `auth_server` at the AP itself with a matching
`auth_server_shared_secret` and configure `wpa_psk_radius=2` (or
`sae_password_psk=1`) on the bss.

The keys are the `wifi-station` sections of `/etc/config/wireless` — the same
sections the firmware's hostapd.sh turns into the per bss psk/sae files:

```
config wifi-station 'anna'
        list mac '00:11:22:33:44:55'
        list mac 'aa:bb:cc:dd:ee:ff'
        option key 'passphrase'
        option vid '7'
```

The section name identifies the key (it is reported as `key` in the events),
`mac` is a list of stations sharing the key — no `mac` at all means every
station — `key` the passphrase (8–63 chars hashed with the SSID, or a 64 char
hex PSK), `vid` an optional VLAN that is handed back to hostapd as tunnel
attributes. When the bss already lives on that vlan itself (its wifi interface
is a bridge port with that pvid), the tunnel attributes are withheld — hostapd
would only put the station back where it already is — and the event reports
`vlan_suppressed` instead of `vlan`. The store is re-read on every
`hostapd-auth` ubus `reload` notification (each applied wifi config) and
additionally checked every `radius_reload_interval` seconds by content digest,
so a `uci commit` + `wifi reload` needs no restart and is visible within
seconds either way.

`/etc/config/apman` itself is watched the same way: when the file changes the
agent re-applies its config and starts, stops, or restarts the RADIUS server
to match (a secret change restarts it). A controller that flips an SSID to the
on-AP server therefore only needs to write this file — no restart command,
and the AP keeps answering while the controller is unreachable.

Every decision is logged and published to `radius/auth/<bssid>` (QoS 1, not
retained, feature flag `radius_psk` in `properties/agent`) — see
[docs/controller-api.md](docs/controller-api.md).

## Security

The command topics accept `{"jsonrpc":"2.0","method":"call","params":[...]}`
and execute the call on the local ubus without further authorisation, and
`properties/session/create` publishes a ubus rpc session that is granted
read/write/exec on `/*`. **This is intended** — apman is a fleet management
agent — but it means the broker is the only security boundary. A deployment
therefore needs:

* TLS with a private CA and per-device client certificates
  (`cafile` + `certfile` + `keyfile`), not username/password alone.
* Broker ACLs that restrict every device to its own subtree, e.g. for mosquitto
  with `use_identity_as_username true`:

  ```
  pattern write  apman/ap/%u/#
  pattern read   apman/ap/%u/command
  pattern read   apman/ap/%u/command/bulk
  pattern read   apman/command
  ```

  Write access to `apman/command` and `apman/ap/+/command#` must be limited to
  the management backend — anyone who can publish there owns every AP.
* A broker that is not reachable from the internet without mTLS.

## History

`apman-status-curl`, an HTTP POST variant of the bridge (options `url_event` /
`url_status`), was removed; it was never installed by the package. Recover it
from git history if needed.
