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
