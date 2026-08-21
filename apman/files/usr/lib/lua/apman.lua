#!/usr/bin/env lua

--[[
  A demo of ubus subscriber binding. Should be run after publisher.lua
--]]

require "ubus"
require "uloop"
local cjson = require "cjson"
local socket = require("socket")
local mqtt = require("mosquitto")
-- luasocket ships socket/unix.so in OpenWrt, but a build without it would only
-- fail once a control channel request is made — so check for the datagram
-- constructor here and let the feature report itself as unavailable instead
local have_unix, unix = pcall(require, "socket.unix")
have_unix = have_unix and type(unix) == 'table' and type(unix.dgram) == 'function'
-- the optional minimal radius server (apman-radius.lua) answering hostapd
-- wpa_psk_radius / sae psk mac queries; the feature reports itself absent
-- when the module is not installed
local have_radius, apman_radius = pcall(require, 'apman-radius')
have_radius = have_radius and type(apman_radius) == 'table'

local apman = {}
apman.version = '56-12'			-- keep in sync with the package Makefile
apman.started_at = nil
apman.conn = nil
apman.hostname = nil
apman.config = {}
apman.mqtt_hostname = 'app1.kalnet.hooya.de'
apman.topic_prefix = 'apman/'
apman.client = nil
apman.count = 0
apman.timers = {}
apman.ubus_session = {}
apman.collects_stats_plugin_name = 'apman'

-- runtime defaults, overridable from uci (see apman.apply_config)
apman.status_interval = 10000		-- ms between full status publishes
apman.ubus_check_interval = 1000	-- ms between hostapd object list checks
apman.ubus_settle = 5000		-- ms to wait before resubscribing ubus
apman.mqtt_loop_interval = 200		-- ms between mosquitto loop ticks
apman.mqtt_retry_min = 2		-- s, first reconnect backoff step
apman.mqtt_retry_max = 120		-- s, backoff ceiling
apman.station_dump = true		-- publish raw 'iw station dump' text
apman.command_topic_global = true	-- subscribe the fleet-wide command topic
apman.ubus_check_interval_slow = 30000	-- ms, used once hostapd bss.* events work
apman.hostapd_status = true		-- publish the global hostapd status object
-- extra ubus objects whose notifications are forwarded, and ubus broadcast
-- events that are forwarded. Both are additive, they use their own topics.
apman.subscribe_objects = { 'network.interface', 'network.device' }
apman.listen_events = { 'network.interface' }
apman.have_bss_events = false
-- resend suppression: a payload that did not change is republished only after
-- max_age seconds, so a consumer that lost its state still resyncs
apman.property_republish = 300		-- s, retained properties
apman.wireless_republish = 60		-- s, wireless status
apman.probe_interval = 10		-- s per station, 0 = forward every probe
apman.log_payload_len = 200		-- chars of a payload to log, 0 = full
apman.survey_interval = 300		-- s between channel surveys, 0 = off
apman.survey_last = 0

-- minimal radius server answering hostapd wpa_psk_radius / sae psk queries
-- (see apman-radius.lua); started from apman.init when enabled. The keys are
-- the wifi-station sections of the wireless config, reloaded on hostapd-auth
-- notifications and checked by a digest timer as a safety net
apman.radius_enabled = false
apman.radius_port = 1812
apman.radius_secret = ''
apman.radius_wifi_config = '/etc/config/wireless'
apman.radius_reload_interval = 10	-- s between config change checks, 0 = off
apman.radius_active = false
apman.radius_server = nil
apman.radius_bss_vlans = {}		-- bssid -> the vlan the bss lives on
apman.radius_bss_ifaces = {}		-- bssid -> uci wifi-iface section name
apman.radius_bss_digest = nil		-- gate for the bss map watchdog in radius_reload
apman.radius_bss_ticks = 0		-- full map refreshes every 30 ticks (5 min)
apman.config_digest = nil		-- /etc/config/apman content the watch saw last

-- hostapd control channel (see apman.ctrl_request)
apman.ctrl_dir = '/var/run/hostapd'
apman.ctrl_enabled = true
apman.ctrl_timeout = 3			-- s to wait for an answer
apman.ctrl_allow_all = false		-- ignore the allowlist below
apman.ctrl_seq = 0
apman.ctrl_stale_cleaned = false
-- Persistent monitors on the control channel (ATTACH), one per bss.
--
-- The ubus notifications cover what a client does — probe, auth, assoc,
-- disassoc — and they arrive parsed. The control channel covers what hostapd
-- itself does, and a few things about clients that ubus loses on the way:
--
--   * AP-STA-CONNECTED carries keyid, vlanid and ip_addr, so a key handed out
--     is recognised at the moment it is used instead of on the next poll
--   * BSS-TM-RESP prints status_code as a number, while the ubus path renders
--     it through blobmsg_add_u8 and libubox turns that into a boolean
--   * why a station was refused (max sta, blocked, wrong key) and how the EAP
--     server answered — neither exists over ubus at all
--
-- Measured on a busy access point: 171 ubus notifications against 4 control
-- channel events in the same four minutes, because probe requests do not come
-- through here. The stream is cheap.
apman.ctrl_events = true
apman.ctrl_monitors = {}		-- ifname -> { sock, path, ufd }
apman.ctrl_event_all = false		-- forward everything, not just the list
apman.ctrl_event_allow = {
	-- stations
	['AP-STA-CONNECTED'] = true, ['AP-STA-DISCONNECTED'] = true,
	['AP-STA-POSSIBLE-PSK-MISMATCH'] = true, ['EAPOL-4WAY-HS-COMPLETED'] = true,
	['AP-REJECTED-MAX-STA'] = true, ['AP-REJECTED-BLOCKED-STA'] = true,
	-- steering, with the status code the ubus path cannot carry
	['BSS-TM-RESP'] = true, ['BSS-TM-QUERY'] = true,
	['MBO-CELL-PREFERENCE'] = true, ['MBO-TRANSITION-REASON'] = true,
	-- the eap server, which has no ubus equivalent
	['CTRL-EVENT-EAP-SUCCESS2'] = true, ['CTRL-EVENT-EAP-FAILURE2'] = true,
	['CTRL-EVENT-EAP-TIMEOUT-FAILURE2'] = true, ['CTRL-EVENT-EAP-RETRANSMIT2'] = true,
	['EAP-ERROR-CODE'] = true,
	-- channel life cycle
	['ACS-STARTED'] = true, ['ACS-COMPLETED'] = true, ['ACS-FAILED'] = true,
	['DFS-CAC-START'] = true, ['DFS-CAC-COMPLETED'] = true,
	['DFS-RADAR-DETECTED'] = true, ['DFS-NEW-CHANNEL'] = true,
	['DFS-NOP-FINISHED'] = true, ['DFS-PRE-CAC-EXPIRED'] = true,
	['AP-CSA-FINISHED'] = true, ['CTRL-EVENT-CHANNEL-SWITCH'] = true,
	['CTRL-EVENT-STARTED-CHANNEL-SWITCH'] = true,
	['CTRL-EVENT-REGDOM-CHANGE'] = true,
	-- bss state
	['AP-ENABLED'] = true, ['AP-DISABLED'] = true,
	['INTERFACE-ENABLED'] = true, ['INTERFACE-DISABLED'] = true,
	-- radio behaviour of a client, which explains sudden slowness
	['STA-OPMODE-MAX-BW-CHANGED'] = true, ['STA-OPMODE-SMPS-MODE-CHANGED'] = true,
	['STA-OPMODE-N_SS-CHANGED'] = true,
	-- measurements and protection
	['RRM-NEIGHBOR-REP-RECEIVED'] = true, ['BEACON-REQ-TX-STATUS'] = true,
	['LINK-MSR-RESP-RX'] = true, ['OCV-FAILURE'] = true,
	['CTRL-EVENT-UNPROT-BEACON'] = true,
	['PMKSA-CACHE-ADDED'] = true, ['PMKSA-CACHE-REMOVED'] = true,
	-- wps enrolment
	['WPS-PBC-ACTIVE'] = true, ['WPS-PIN-NEEDED'] = true, ['WPS-SUCCESS'] = true,
	['WPS-FAIL'] = true, ['WPS-TIMEOUT'] = true, ['WPS-OVERLAP-DETECTED'] = true,
	['WPS-ENROLLEE-SEEN'] = true, ['WPS-REG-SUCCESS'] = true, ['WPS-CANCEL'] = true,
}
-- BEACON-RESP-RX is deliberately absent: the ubus beacon-report notification
-- delivers the same measurement already decoded.
-- Extra detail pulled from the control channel and folded into the periodic
-- status. Both are cached and refreshed asynchronously, so building a status
-- message never waits for hostapd: what arrives lands in the next message.
--
-- The per station values (which AKM and cipher a client actually negotiated,
-- the key handshake state, its power save behaviour) do not change while the
-- association lasts, so only stations that are new or stale cost a request.
apman.mib_interval = 60			-- s per bss, 0 = off
apman.sta_ctrl_interval = 300		-- s per station, 0 = off
apman.sta_ctrl_retry = 30		-- s, for stations that report no identity yet
apman.mib_cache = {}			-- ifname -> { ts, values }
apman.sta_ctrl_cache = {}		-- ifname -> mac -> { ts, values }
-- what is kept from a MIB reply; the rest is either constant or noise
apman.mib_fields = {
	'dot11RSNA4WayHandshakeFailures', 'dot11RSNATKIPCounterMeasuresInvoked',
	'dot11RSNAAuthenticationSuiteSelected', 'dot11RSNAPairwiseCipherSelected',
	'dot11RSNAGroupCipherSelected', 'hostapdWPAGroupState',
	'radiusAuthServerAddress', 'radiusAuthClientServerPortNumber',
	'radiusAuthClientRoundTripTime', 'radiusAuthClientAccessRequests',
	'radiusAuthClientAccessAccepts', 'radiusAuthClientAccessRejects',
	'radiusAuthClientAccessChallenges', 'radiusAuthClientAccessRetransmissions',
	'radiusAuthClientTimeouts', 'radiusAuthClientMalformedAccessResponses',
	'radiusAuthClientBadAuthenticators', 'radiusAuthClientPendingRequests',
}
-- and from a STA reply
apman.sta_ctrl_fields = {
	-- keyid names the entry of the wpa_psk_file a station authenticated with,
	-- which is the only way to tell apart clients that share a wildcard mac
	'keyid',
	'AKMSuiteSelector', 'dot11RSNAStatsSelectedPairwiseCipher',
	'hostapdWPAPTKState', 'hostapdWPAPTKGroupState', 'hostapdMFPR',
	'capability', 'listen_interval', 'supported_rates', 'timeout_next',
	'dot11RSNAStatsTKIPLocalMICFailures', 'dot11RSNAStatsTKIPRemoteMICFailures',
	'wpa', 'ht_caps_info', 'vht_caps_info', 'he_caps_info',
}
-- Commands the controller may send. Everything here either reads state or does
-- something the ubus interface cannot do at all. Deliberately absent:
-- DISASSOCIATE, DEAUTHENTICATE, DENY_ACL/ACCEPT_ACL add/del, RELOAD, DISABLE —
-- they either exist over ubus already or cut clients off, and a command
-- channel without authentication should not offer them by default.
-- 'option ctrl_allow_all 1' lifts this, 'list ctrl_allow <VERB>' extends it.
apman.ctrl_allowed = {
	['STATUS'] = true, ['STATUS-DRIVER'] = true, ['GET_CONFIG'] = true,
	['MIB'] = true, ['STA'] = true, ['STA-FIRST'] = true, ['STA-NEXT'] = true,
	['SIGNATURE'] = true, ['SHOW_NEIGHBOR'] = true, ['GET_CAPABILITY'] = true,
	['DENY_ACL'] = true, ['ACCEPT_ACL'] = true,
	['RELOAD_WPA_PSK'] = true, ['BSS_TM_REQ'] = true,
	-- withdrawing a key needs this: a station that was deauthenticated
	-- comes back through its cached PMKSA without running SAE or the four
	-- way handshake again, and would keep using the key that was just
	-- taken away (measured 2026-08-21, auth_alg=open on an SAE bss)
	['PMKSA_FLUSH'] = true,
	['WPS_PIN'] = true, ['WPS_PBC'] = true, ['WPS_CANCEL'] = true,
	['REQ_BEACON'] = true, ['REQ_LINK_MEASUREMENT'] = true,
}

-- ubus status codes, so a consumer gets a reason instead of a bare null
apman.ubus_status_text = {
	[0] = 'ok', [1] = 'invalid command', [2] = 'invalid argument',
	[3] = 'method not found', [4] = 'not found', [5] = 'no data',
	[6] = 'permission denied', [7] = 'timeout', [8] = 'not supported',
	[9] = 'unknown error', [10] = 'connection failed', [11] = 'no memory',
	[12] = 'parse error', [13] = 'system error',
}
apman.published = {}			-- topic -> { payload, ts }
apman.probe_seen = {}			-- object/address -> ts
apman.probe_count = 0

-- mqtt connection state (never block the uloop, see apman.mqttCallback)
apman.mqtt_connected = false
apman.mqtt_started = false
apman.mqtt_backoff = 0
apman.mqtt_next_attempt = 0
apman.mqtt_attempts = 0
apman.ubus_subscribed = false
apman.ubus_resubscribe = nil

function apman.starts_with(str, start)
	return str:sub(1, #start) == start
end

-- uci leaves unset options as empty strings, treat those as absent
function apman.cfg(name, default)
	local value = apman.config[name]
	if value == nil or value == '' then
		return default
	end
	return value
end

function apman.cfg_num(name, default)
	local value = tonumber(apman.cfg(name, false))
	if value == nil then
		return default
	end
	return value
end

-- uci lists arrive as a table, a single option as a string
function apman.cfg_list(name, default)
	local value = apman.config[name]
	if type(value) == 'table' then
		return value
	end
	if type(value) == 'string' and value ~= '' then
		return { value }
	end
	return default
end

function apman.cfg_bool(name, default)
	local value = apman.cfg(name, nil)
	if value == nil then
		return default
	end
	return value == '1' or value == 'true' or value == 'yes' or value == 'on'
end

-- command payloads are several kB each and used to be logged in full on every
-- call, which dominated the syslog on a busy ap
function apman.trunc(str)
	if type(str) ~= 'string' then
		str = tostring(str)
	end
	if apman.log_payload_len <= 0 or #str <= apman.log_payload_len then
		return str
	end
	return string.sub(str, 1, apman.log_payload_len) .. string.format('...(%d bytes)', #str)
end

function apman.ap_topic(suffix)
	return apman.topic_prefix .. 'ap/' .. apman.hostname .. '/' .. suffix
end

function apman.getOutput(cmd)
	local f = io.popen (cmd)
	local output = f:read("*a") or ""
	f:close()
	return output
end

-- probe requests are by far the highest volume notification and carry no state,
-- so only one per station and probe_interval is forwarded
function apman.probe_throttled(object, msg)
	if apman.probe_interval <= 0 or type(msg) ~= 'table' or msg['address'] == nil then
		return false
	end

	local now = socket.gettime()
	local key = object .. '/' .. msg['address']
	local last = apman.probe_seen[key]
	if last ~= nil and (now - last) < apman.probe_interval then
		return true
	end
	apman.probe_seen[key] = now

	apman.probe_count = apman.probe_count + 1
	if apman.probe_count > 500 then
		apman.probe_count = 0
		local cutoff = now - (apman.probe_interval * 4)
		for k, ts in pairs(apman.probe_seen) do
			if ts < cutoff then
				apman.probe_seen[k] = nil
			end
		end
	end
	return false
end

function apman.createUbusCallback(object, topic)
	return {
		notify = function( msg, method )
			local ltopic = topic .. '/' .. method
			if method == 'probe' and apman.probe_throttled(object, msg) then
				return
			end
			if type(msg) == 'table' then
				msg['timestamp'] = socket.gettime()
			end
			apman.publish_mqtt( ltopic, cjson.encode(msg))
			--print(string.format("Published from object '%s' to mqtt topic '%s', payload: %s", object, ltopic, cjson.encode(msg)))
			-- the ucode based hostapd announces bss changes on its global
			-- object, no need to poll the object list for them
			if object == 'hostapd' and apman.starts_with(method, 'bss.') then
				apman.schedule_resubscribe(method)
			end
		end
	}
end

-- forwards a ubus broadcast event (ubus listen) to its own mqtt topic
function apman.createEventCallback(event)
	local topic = apman.ap_topic('events/' .. event:gsub('%.', '/'))
	return function(msg)
		if type(msg) ~= 'table' then
			msg = { ['message'] = msg }
		end
		msg['event'] = event
		msg['timestamp'] = socket.gettime()
		apman.publish_mqtt(topic, cjson.encode(msg))
	end
end

function apman.schedule_resubscribe(reason)
	if apman.ubus_resubscribe ~= nil then
		return
	end
	print(string.format("hostapd reported '%s', resubscribing in %ds.", tostring(reason), apman.ubus_settle / 1000))
	apman.ubus_resubscribe = 1
	apman.timers['ubus_check']:set(apman.ubus_settle)
end

-- drives the mosquitto client and owns the (non blocking) reconnect schedule
function apman.mqttCallback()
	if apman.mqtt_started then
		apman.client:loop(0)
	end
	if not apman.mqtt_connected and socket.gettime() >= apman.mqtt_next_attempt then
		apman.connect_mqtt()
	end
	apman.timers['mqtt']:set(apman.mqtt_loop_interval)
end

function apman.ubusCheckCallback()
	local c2 = 0
	-- the connection can be gone right after boot; the poll must stay armed
	-- or the whole resubscribe machinery dies quietly
	local objects = apman.conn and apman.conn:objects()
	if not objects then
		apman.timers['ubus_check']:set(apman.ubus_check_interval)
		return
	end
	for key, object in pairs(objects) do
		if apman.starts_with(object, "hostapd") then
			c2 = c2 + 1
		end
	end
	if apman.ubus_resubscribe ~= nil then
		-- the settle delay has passed, pick up the new object list
		apman.ubus_resubscribe = nil
		print('Restarting ubus connection and subscriptions.')
		apman.reconnect_ubus()
		apman.subscribeCallback()
	elseif apman.count ~= c2 then
		print(string.format('Ubus object list changed, waiting %ds before resubscribing.', apman.ubus_settle / 1000))
		apman.ubus_resubscribe = 1
		apman.timers['ubus_check']:set(apman.ubus_settle)
		return
	end
	-- with bss.* notifications this poll is only a safety net
	if apman.have_bss_events then
		apman.timers['ubus_check']:set(apman.ubus_check_interval_slow)
	else
		apman.timers['ubus_check']:set(apman.ubus_check_interval)
	end
end

-- merge the assoclist of 'device' into 'target', tagging every entry with the
-- interface it was seen on (VLAN slaves report their own device)
function apman.merge_assoclist(target, device)
	local list = apman.conn:call("iwinfo", "assoclist", { device = device })
	if type(list) ~= 'table' or type(list['results']) ~= 'table' then
		return target
	end
	for key, entry in pairs(list['results']) do
		if type(entry) == 'table' then
			entry['device'] = device
		end
	end
	if type(target) ~= 'table' or type(target['results']) ~= 'table' then
		return list
	end
	for key, entry in pairs(list['results']) do
		table.insert(target['results'], entry)
	end
	return target
end

-- one 'iw' invocation for all devices instead of one per device: the station
-- dump tags every station with '(on <dev>)', so a single combined run can be
-- split up again afterwards
function apman.collect_station_dumps(devlist)
	local dumps = {}
	local cmd = {}

	for key, device in pairs(devlist) do
		dumps[device] = {}
		table.insert(cmd, "iw dev " .. device .. " station dump")
	end
	if #cmd == 0 then
		return dumps
	end

	local output = apman.getOutput(table.concat(cmd, "; "))
	local pos, len, current = 1, #output, nil
	while pos <= len do
		local line
		local nl = string.find(output, "\n", pos, true)
		if nl then
			line = string.sub(output, pos, nl - 1)
			pos = nl + 1
		else
			line = string.sub(output, pos)
			pos = len + 1
		end
		local device = string.match(line, "^Station %S+ %(on (%S+)%)")
		if device ~= nil then
			current = device
			if dumps[current] == nil then
				dumps[current] = {}
			end
		end
		if current ~= nil then
			table.insert(dumps[current], line)
		end
	end

	local result = {}
	for device, lines in pairs(dumps) do
		if #lines > 0 then
			result[device] = table.concat(lines, "\n") .. "\n"
		else
			result[device] = ""
		end
	end
	return result
end

-- Turn the station dump text into a map station -> fields.
--
-- The consumer used to do this with string operations on every status message,
-- ten times a second in a single process. Doing it here spreads the work over
-- the access points and it only happens once per interval anyway. Payload
-- version 2 marks the structured form.
function apman.parse_station_dump(text)
	local stations = {}
	local current = nil
	local pos, len = 1, #text

	while pos <= len do
		local line
		local nl = string.find(text, "\n", pos, true)
		if nl then
			line = string.sub(text, pos, nl - 1)
			pos = nl + 1
		else
			line = string.sub(text, pos)
			pos = len + 1
		end

		local mac = string.match(line, "^Station (%x%x:%x%x:%x%x:%x%x:%x%x:%x%x)")
		if mac ~= nil then
			current = string.lower(mac)
			stations[current] = { device = string.match(line, "%(on (%S+)%)") }
		elseif current ~= nil then
			local key, value = string.match(line, "^%s*(.-):%s*(.*)$")
			if key ~= nil and key ~= '' then
				-- same normalisation the consumer used, so the field names
				-- stay the ones everything downstream already knows
				key = string.gsub(key, "[ ,%.%-/]", "_")
				stations[current][key] = value
			end
		end
	end

	return stations
end

function apman.statusCallback()
	local topic, devices, data
	local devices = apman.conn:call("iwinfo", "devices", {})
	data = {}
	data['devices'] = {}
	local iwinfo = {}
	local slaves = {}
	local masters = {}
	local dumpdevs = {}
	local hostapd_status = nil

	-- global hostapd object (ucode based hostapd): authoritative bss/radio
	-- topology including mld links. Published as its own topic and mirrored
	-- into every device payload, the existing keys stay untouched.
	if apman.hostapd_status then
		hostapd_status = apman.conn:call("hostapd", "status", {})
		if type(hostapd_status) == 'table' then
			hostapd_status['timestamp'] = socket.gettime()
			apman.publish_mqtt(apman.ap_topic('hostapd/status'), cjson.encode(hostapd_status))
		end
	end

	-- a bss can disappear between the two calls — hostapd tearing an
	-- interface down leaves it in the device list while info already
	-- answers nil — and an unchecked index there kills the whole agent
	local devlist = {}
	if type(devices) == 'table' and type(devices['devices']) == 'table' then
		devlist = devices['devices']
	end

	for key, value in pairs(devlist) do
		local info = apman.conn:call("iwinfo", "info", { device = value })
		if type(info) == 'table' then
			iwinfo[value] = info
			local is_master = 1
			if info['mode'] ~= nil and info['mode'] == 'Master (VLAN)' then
				for k2, v2 in pairs(devlist) do
					local s = v2
					if value ~= s and string.sub(value, 0, string.len(s)) == s then
						local master = v2
						is_master = 0
						if slaves[master] == nil then
							slaves[master] = {}
						end
						table.insert(slaves[master], value)
						--print('added slave '..value..' to master '..master)
					end
				end

			end
			if is_master then
				--print('Add master '..value)
				table.insert(masters, value)
			end
		end
	end

	for key, value in pairs(masters) do
		data['devices'][value] = {}
		data['devices'][value]['timestamp'] = socket.gettime()
		data['devices'][value]['info'] = iwinfo[value]
		data['devices'][value]['clients'] = apman.conn:call("hostapd."..value, "get_clients", {})
		data['devices'][value]['assoclist'] = apman.merge_assoclist(nil, value)
		if slaves[value] ~= nil then
			for k2, subdevice in pairs(slaves[value]) do
				--print('queried slave '..subdevice)
				data['devices'][value]['assoclist'] = apman.merge_assoclist(data['devices'][value]['assoclist'], subdevice)
			end
		end
		data['devices'][value]['status'] = apman.conn:call("network.device", "status", { name = value })
		data['devices'][value]['ap_status'] = apman.conn:call("hostapd."..value, "get_status", {})
		if type(hostapd_status) == 'table' and type(hostapd_status['interfaces']) == 'table' then
			data['devices'][value]['hostapd_status'] = hostapd_status['interfaces'][value]
		end
		-- dump every interface, not only those with entries in the assoclist:
		-- p2p/mesh peers never show up there
		if apman.station_dump then
			table.insert(dumpdevs, value)
			if slaves[value] ~= nil then
				for k2, subdevice in pairs(slaves[value]) do
					table.insert(dumpdevs, subdevice)
				end
			end
		end
	end

	local dumps = {}
	if apman.station_dump then
		dumps = apman.collect_station_dumps(dumpdevs)
	end

	apman.publish_survey(masters)

	for key, value in pairs(masters) do
		data['devices'][value]['v'] = 2
		if apman.station_dump then
			local stations = dumps[value] or ""
			if slaves[value] ~= nil then
				for k2, subdevice in pairs(slaves[value]) do
					stations = stations .. "\n" .. (dumps[subdevice] or "")
				end
			end
			data['devices'][value]['stations'] = apman.parse_station_dump(stations)
		end

		-- control channel detail: what is cached goes out now, what aged out
		-- is fetched asynchronously and is in the next message
		local macs = {}
		local assoclist = data['devices'][value]['assoclist']
		if type(assoclist) == 'table' and type(assoclist['results']) == 'table' then
			for _, entry in ipairs(assoclist['results']) do
				if type(entry) == 'table' and entry['mac'] ~= nil then
					macs[#macs + 1] = entry['mac']
				end
			end
		end
		apman.refresh_mib(value)
		apman.refresh_sta_ctrl(value, macs)
		local mib = apman.mib_cache[value]
		if mib ~= nil and mib.values ~= nil then
			data['devices'][value]['mib'] = mib.values
		end
		data['devices'][value]['sta_ctrl'] = apman.sta_ctrl_values(value)

		topic = apman.ap_topic('device/hostapd/' .. value .. '/status')
		data['devices']['timestamp'] = socket.gettime()
		apman.publish_mqtt( topic , cjson.encode(data['devices'][value]))
		--print("Published data to mqtt topic '"..topic.."'.")
	end

        topic = apman.ap_topic('online')
	apman.publish_mqtt(topic, cjson.encode({['status'] = 'online', ["timestamp"] = socket.gettime()}))

	data = apman.conn:call("system", "info", {})
	if type(data) == 'table' then
		data['timestamp'] = socket.gettime()
	end
	topic = apman.ap_topic('properties/system/info')
	apman.publish_mqtt( topic , cjson.encode(data))

	-- by far the largest single payload and almost always identical: publish
	-- it on change, plus a periodic refresh so a consumer can resync
	data = apman.conn:call("network.wireless", "status", {})
	topic = apman.ap_topic('wireless/status')
	if type(data) == 'table' then
		local unchanged = cjson.encode(data)
		local last = apman.published[topic]
		if last == nil or last.payload ~= unchanged
		   or (socket.gettime() - last.ts) >= apman.wireless_republish then
			data['timestamp'] = socket.gettime()
			if apman.publish_mqtt( topic , cjson.encode(data)) ~= nil then
				apman.published[topic] = { payload = unchanged, ts = socket.gettime() }
			end
		end
	else
		apman.publish_mqtt( topic , cjson.encode(data))
	end

	apman.timers['status']:set(apman.status_interval)
end

function apman.reconnect_ubus()
	apman.conn:close()
	return apman.connect_ubus()
end

function apman.connect_ubus()
	apman.conn = ubus.connect()
	if not apman.conn then
		error("Failed to connect to ubus")
		return
	end
end

function apman.mqtt_log(level, message)
	-- print('mosquitto ' .. level .. ':' .. message)
end

-- registers the configured ubus broadcast events; has to be redone after every
-- ubus reconnect, the handlers die with the connection
function apman.listen_ubus()
	local handlers = {}
	local count = 0

	for key, event in pairs(apman.listen_events) do
		handlers[event] = apman.createEventCallback(event)
		count = count + 1
	end
	if count < 1 then
		return
	end

	local ok, err = pcall(function()
		apman.conn:listen(handlers)
	end)
	if ok then
		for event in pairs(handlers) do
			print(string.format("Listening for ubus event '%s'.", event))
		end
	else
		print(string.format("Failed to listen for ubus events: %s", tostring(err)))
	end
end

-- retries the subscription until hostapd shows up on ubus, driven by a timer
-- instead of a sleep loop so mqtt and the status publishes keep running
function apman.subscribeCallback()
	if not apman.subscribe_ubus() then
		apman.timers['subscribe']:set(1000)
	end
end

-- one pass over the ubus object list; returns false while no hostapd object
-- is present yet
function apman.subscribe_ubus()
	local topic, devices, data
	-- gone right after boot; the caller retries a second later
	local objects = apman.conn and apman.conn:objects()
	if not objects then
		return false
	end
	local available = {}

	apman.count = 0
	for key, object in pairs(objects) do
		available[object] = true
		if apman.starts_with(object, "hostapd") then
			local topic = apman.ap_topic('notifications/hostapd/' .. object:gsub('%hostapd.',''))
			print(string.format("Adding subscription for object '%s', assigning to topic '%s'.", object, topic))
			apman.conn:subscribe(object, apman.createUbusCallback(object, topic))
			apman.count = apman.count + 1
		end
	end
	if apman.count < 1 then
		return false
	end
	-- the same list drives the control channel monitors; hostapd loses them on
	-- every restart, and this runs again on bss.add/bss.remove/bss.reload
	local monitored = {}
	for object in pairs(available) do
		if apman.starts_with(object, 'hostapd.') then
			monitored[object:gsub('^hostapd%.', '')] = true
		end
	end
	apman.ctrl_monitor_sync(monitored)
	-- the global 'hostapd' object only exists with the ucode based hostapd;
	-- its bss.add/bss.remove/bss.reload notifications replace the poll
	apman.have_bss_events = available['hostapd'] == true

	-- hostapd-auth announces every applied wifi config (config_set ->
	-- reload). The radius keys come from the wifi-station sections of that
	-- config, so re-read them on the spot instead of waiting for the digest
	-- timer; the other notifications it sends (sta_auth, sta_connected) are
	-- not ours to forward here.
	if available['hostapd-auth'] and apman.radius_active then
		local ok, err = pcall(function()
			apman.conn:subscribe('hostapd-auth', {
				notify = function(msg, method)
					if method == 'reload' then
						apman.radius_reload()
					end
				end
			})
		end)
		if ok then
			print('Subscribing to hostapd-auth for radius key reloads.')
		else
			print(string.format('Failed to subscribe hostapd-auth: %s', tostring(err)))
		end
	end

	-- additional objects (netifd and friends), published below their own
	-- topic so nothing that exists today changes
	for key, object in pairs(apman.subscribe_objects) do
		if available[object] then
			local topic = apman.ap_topic('notifications/' .. object:gsub('%.', '/'))
			local ok, err = pcall(function()
				apman.conn:subscribe(object, apman.createUbusCallback(object, topic))
			end)
			if ok then
				print(string.format("Adding subscription for object '%s', assigning to topic '%s'.", object, topic))
			else
				print(string.format("Failed to subscribe object '%s': %s", object, tostring(err)))
			end
		else
			print(string.format("Skipping subscription for absent object '%s'.", object))
		end
	end

	apman.listen_ubus()

	-- add rrm information; a bss can disappear between the object list and
	-- these calls, and an unchecked index kills the whole agent (the same
	-- guard statusCallback uses)
	local devlist = {}
	local devices = apman.conn:call("iwinfo", "devices", {})
	if type(devices) == 'table' and type(devices['devices']) == 'table' then
		devlist = devices['devices']
	end
	for key, value in pairs(devlist) do
		local rrm = apman.conn:call("hostapd."..value, "rrm_nr_get_own", {})
		if type(rrm) == 'table' then
			topic = apman.ap_topic('properties/hostapd/' .. value .. '/rrm_nr_get_own')
			-- resubscribes happen often, the neighbour report almost never
			-- changes: do not republish it every time
			apman.publish_property( topic , cjson.encode(rrm), 1, true, apman.property_republish)
		end
		-- static bss configuration (ssid, encryption, hw mode), ucode
		-- based hostapd only
		if available['hostapd'] then
			local info = apman.conn:call("hostapd", "bss_info", { iface = value })
			if type(info) == 'table' then
				topic = apman.ap_topic('properties/hostapd/' .. value .. '/bss_info')
				apman.publish_property( topic , cjson.encode(info), 1, true, apman.property_republish)
			end
		end
	end
	-- send session
	data = apman.get_rpc_session_ubus()
	if type(data) == 'table' then
		data['timestamp'] = socket.gettime()
	end
	topic = apman.ap_topic('properties/session/create')
	apman.publish_mqtt( topic , cjson.encode(data))
	apman.publish_agent()
	-- this also runs after every bss.* change (wifi reloads, hostapd
	-- restarts): the radius store picks up whatever the config change was
	-- about, the digest guard keeps the common no-op cheap
	apman.radius_reload()
	return true
end

function apman.get_rpc_session_ubus()
	local topic, session, opts
	if not apman.conn then
		return nil
	end
	session = apman.conn:call("session", "create", { timeout = 0 })
	if type(session) ~= 'table' or session['ubus_rpc_session'] == nil then
		-- the caller drops a nil answer; indexing a half answer must not
		-- take the agent down at boot
		print(string.format("Result of session create: %s", cjson.encode(session)))
		return nil
	end
	print(string.format("Result of session create: %s", cjson.encode(session)))

	local result
	result = apman.conn:call("session", "list", { ubus_rpc_session = session['ubus_rpc_session'] })
	print(string.format("Result of session list: %s", cjson.encode(result)))

	-- rpcd expects each entry as an array [object, function] and silently
	-- skips anything else, so a map here granted nothing at all
	opts = { scope = 'file',  objects = {}, ubus_rpc_session = session['ubus_rpc_session']}
	table.insert(opts['objects'], {'/*', 'read'})
	table.insert(opts['objects'], {'/*', 'write'})
	table.insert(opts['objects'], {'/*', 'exec'})
	print(string.format("Opts for session grant: %s", cjson.encode(opts)))
	result = apman.conn:call("session", "grant", opts)
	print(string.format("Result of session gant: %s", cjson.encode(result)))

	-- rpcd checks uci access in its own scope, not in 'file'. Without this the
	-- session can read and write files but every uci call comes back as
	-- permission denied, which also rules out the rollback safe
	-- uci apply/confirm that needs a session.
	opts = { scope = 'uci', objects = {}, ubus_rpc_session = session['ubus_rpc_session']}
	table.insert(opts['objects'], {'*', 'read'})
	table.insert(opts['objects'], {'*', 'write'})
	result = apman.conn:call("session", "grant", opts)
	print(string.format("Result of uci scope grant: %s", cjson.encode(result)))

	result = apman.conn:call("session", "list", { ubus_rpc_session = session['ubus_rpc_session'] })
	print(string.format("Result of session list: %s", cjson.encode(result)))

	apman.session = session
	return session
end

-- builds the client (credentials, tls, last will). Does not connect: the
-- connection itself is driven by apman.mqttCallback / apman.connect_mqtt.
function apman.setup_mqtt()
	local topic
	local mqtt_host, mqtt_port, mqtt_keepalive, mqtt_clientid

	-- mqtt setup
	if apman.config['mqtt_clientid'] then
		apman.client = mqtt.new(apman.config['mqtt_clientid'], false)
	else
		apman.client = mqtt.new(apman.hostname, false)
	end
	-- assign MQTT client event handlers

	apman.client.ON_LOG = apman.mqtt_log

	apman.client.ON_MESSAGE = apman.on_mqtt_message
	apman.client.ON_CONNECT = apman.on_mqtt_connect
	apman.client.ON_DISCONNECT = apman.on_mqtt_disconnect
	if apman.config['mqtt_username'] then
		local mqtt_password
		if apman.config['mqtt_password'] then
			mqtt_password = apman.config['mqtt_password']
		end
		apman.client:login_set(apman.config['mqtt_username'], mqtt_password)
	end
	if true then
		local cafile, capath, certfile, keyfile
		if apman.config['cafile'] then
			cafile = apman.config['cafile']
		end
		if apman.config['capath'] then
			capath = apman.config['capath']
		end
		if apman.config['certfile'] then
			certfile = apman.config['certfile']
		end
		if apman.config['keyfile'] then
			keyfile = apman.config['keyfile']
		end
		if cafile or capath or certfile or keyfile then
			apman.client:tls_set(cafile, capath, certfile, keyfile)
		end
	end
	if true then
		local cert, tls_version, ciphers
		if apman.config['cert'] then
			cert = apman.config['cert']
		end
		if apman.config['tls_version'] then
			tls_version = apman.config['tls_version']
		end
		if apman.config['ciphers'] then
			ciphers = apman.config['ciphers']
		end
		if cert and (tls_version or ciphers) then
			apman.client:tls_opts_set(cert, tls_version, ciphers)
		end
	end

	if type(apman.config['tls_insecure']) == 'string' then
		apman.client:tls_insecure_set(apman.config['tls_insecure'])
	end

	mqtt_host = apman.mqtt_hostname
	if apman.config['mqtt_host'] then
		mqtt_host = apman.config['mqtt_host']
	end
	if apman.config['mqtt_port'] then
		mqtt_port = apman.config['mqtt_port']
	end
	if apman.config['mqtt_keepalive'] then
		mqtt_keepalive = apman.config['mqtt_keepalive']
	end
	apman.mqtt_host = mqtt_host
	apman.mqtt_port = tonumber(mqtt_port)
	apman.mqtt_keepalive = tonumber(mqtt_keepalive)

	-- set last will (must be done before connection)
	topic = apman.ap_topic('online')
	apman.client:will_set(topic, cjson.encode({['status']='offline'}), 1, false)
end

-- exponential backoff with jitter, so a whole fleet does not hammer the
-- broker in lockstep after it comes back
function apman.mqtt_backoff_next()
	local delay = apman.mqtt_backoff * 2
	if delay < apman.mqtt_retry_min then
		delay = apman.mqtt_retry_min
	end
	if delay > apman.mqtt_retry_max then
		delay = apman.mqtt_retry_max
	end
	apman.mqtt_backoff = delay
	return delay / 2 + math.random() * (delay / 2)
end

-- single non blocking connection attempt; the handshake completes in
-- apman.mqttCallback and lands in apman.on_mqtt_connect
function apman.connect_mqtt()
	local ok, errno, err

	apman.mqtt_attempts = apman.mqtt_attempts + 1
	if apman.mqtt_started then
		ok, errno, err = apman.client:reconnect_async()
	else
		ok, errno, err = apman.client:connect_async(apman.mqtt_host, apman.mqtt_port, apman.mqtt_keepalive)
		apman.mqtt_started = true
	end

	local delay = apman.mqtt_backoff_next()
	apman.mqtt_next_attempt = socket.gettime() + delay
	if not ok then
		print(string.format("Mqtt connection attempt %d failed (%s), retrying in %.1fs.",
			apman.mqtt_attempts, tostring(err), delay))
	end
end

function apman.on_mqtt_connect(success, rc, str)
	if not success then
		apman.mqtt_connected = false
		print(string.format("Mqtt connection refused: %s", tostring(str)))
		return
	end

	local topic, data
	apman.mqtt_connected = true
	apman.mqtt_backoff = 0
	apman.mqtt_attempts = 0
	-- a fresh session may have lost our retained state, resend everything once
	apman.published = {}
	print(string.format("Mqtt connected to %s.", tostring(apman.mqtt_host)))

	topic = apman.ap_topic('online')
	apman.publish_mqtt(topic, cjson.encode({['status'] = 'online', ["timestamp"] = socket.gettime()}))

	-- subscribe command topics
	if apman.command_topic_global then
		topic = apman.topic_prefix .. 'command'
		apman.client:subscribe(topic, 1)
		print("Waiting for commands on topic: ", topic)
	end
	topic = apman.ap_topic('command')
	apman.client:subscribe(topic, 1)
	print("Waiting for commands on topic: ", topic)
	topic = apman.ap_topic('command/bulk')
	apman.client:subscribe(topic, 1)
	print("Waiting for commands on topic: ", topic)

	-- initial publish
	--- system.board
	data = apman.conn:call("system", "board", {})
	if type(data) == 'table' then
		data['timestamp'] = socket.gettime()
	end
	topic = apman.ap_topic('properties/system/board')
	apman.publish_mqtt( topic , cjson.encode(data), 1, true)
	--- system.info
	data = apman.conn:call("system", "info", {})
	if type(data) == 'table' then
		data['timestamp'] = socket.gettime()
	end
	topic = apman.ap_topic('properties/system/info')
	apman.publish_mqtt( topic , cjson.encode(data))

	apman.publish_agent()

	if not apman.ubus_subscribed then
		apman.ubus_subscribed = true
		-- inform about boot up
		apman.publish_mqtt(apman.ap_topic('booted'), cjson.encode({}))
		apman.subscribeCallback()
		apman.statusCallback()
	end
end

-- validates a jsonrpc request, returns nil or an error object
-- The hostapd control channel, proxied.
--
-- hostapd listens on a unix DATAGRAM socket per bss (plus a global one) even
-- though the ubus interface is up — the two are independent and several
-- clients may talk at once, which is how hostapd_cli and wpa_cli coexist. It
-- reaches things ubus does not expose: RELOAD_WPA_PSK (reload the psk file
-- without touching associations), WPS_PIN with an argument, and BSS_TM_REQ
-- whose response event carries the transition status as text instead of the
-- u8 that libubox renders as a boolean.
--
-- Two traps, both found the hard way:
--
--  * hostapd runs inside a ujail as user 'network'. A reply socket in /tmp is
--    invisible to it and the request simply times out. It has to live in
--    ctrl_dir, which the jail has read-write.
--  * a socket bound by root is 0755, so hostapd may not write back. It needs
--    to be world writable before the request goes out.
function apman.ctrl_verb(command)
	local verb = string.match(tostring(command), '^%s*([%w_-]+)')
	return verb and string.upper(verb) or nil
end

function apman.ctrl_permitted(command)
	if apman.ctrl_allow_all then
		return true
	end
	local verb = apman.ctrl_verb(command)
	return verb ~= nil and apman.ctrl_allowed[verb] == true
end

-- ask one bss and call back with the raw answer; never blocks the uloop
function apman.ctrl_request(iface, command, callback)
	if not apman.ctrl_enabled then
		return callback(nil, { code = 8, message = 'control channel proxy disabled' })
	end
	if not have_unix then
		return callback(nil, { code = 8, message = 'luasocket without unix socket support' })
	end
	if type(iface) ~= 'string' or iface == '' or string.find(iface, '[/%s]') ~= nil then
		return callback(nil, { code = 2, message = 'invalid interface name' })
	end
	if type(command) ~= 'string' or command == '' then
		return callback(nil, { code = 2, message = 'command must be a non empty string' })
	end
	if not apman.ctrl_permitted(command) then
		return callback(nil, { code = 6, message = 'command not allowed: ' ..
			tostring(apman.ctrl_verb(command)) })
	end

	local target = apman.ctrl_dir .. '/' .. iface
	apman.ctrl_seq = apman.ctrl_seq + 1
	local path = string.format('%s/apman-%d-%d', apman.ctrl_dir, apman.pid or 0, apman.ctrl_seq)

	local sock = unix.dgram()
	if sock == nil then
		return callback(nil, { code = 11, message = 'cannot create socket' })
	end

	local done = false
	local ufd, timer
	local function cleanup()
		if ufd ~= nil then pcall(function() ufd:delete() end) end
		if timer ~= nil then pcall(function() timer:cancel() end) end
		pcall(function() sock:close() end)
		os.remove(path)
	end
	local function finish(reply, err)
		if done then
			return
		end
		done = true
		cleanup()
		callback(reply, err)
	end

	local ok, err = sock:bind(path)
	if not ok then
		cleanup()
		return callback(nil, { code = 13, message = 'bind failed: ' .. tostring(err) })
	end
	-- hostapd is not root, it has to be able to answer
	os.execute("chmod 0777 '" .. path .. "' 2>/dev/null")

	ok, err = sock:connect(target)
	if not ok then
		cleanup()
		return callback(nil, { code = 4, message = 'no control socket for ' .. iface })
	end
	sock:settimeout(0)

	ok, err = sock:send(command)
	if not ok then
		cleanup()
		return callback(nil, { code = 13, message = 'send failed: ' .. tostring(err) })
	end

	ufd = uloop.fd_add(sock, function()
		local reply = sock:receive(65536)
		if reply == nil then
			return		-- spurious wakeup, keep waiting for the deadline
		end
		finish(reply, nil)
	end, uloop.ULOOP_READ)

	timer = uloop.timer(function()
		finish(nil, { code = 7, message = 'no answer from hostapd within ' ..
			apman.ctrl_timeout .. ' s' })
	end, apman.ctrl_timeout * 1000)
end

-- hostapd answers in "key=value" lines, sometimes with a bare first line (the
-- station address in a STA dump). Both forms are handed on: the raw text so
-- nothing is lost, and the parsed pairs so a consumer does not have to.
function apman.ctrl_parse(reply)
	local values, lines = {}, {}
	for line in string.gmatch(reply, '[^\n]+') do
		lines[#lines + 1] = line
		local key, value = string.match(line, '^([^=]+)=(.*)$')
		if key ~= nil then
			values[key] = value
		end
	end

	return { raw = reply, values = values, lines = lines }
end

-- One line of the control channel event stream.
--
--   <3>AP-STA-CONNECTED 00:11:22:33:44:55 auth_alg=open keyid=17-anna vlanid=7
--
-- The number in brackets is the syslog priority, then the event name, then an
-- optional station address and free "key=value" fields.
function apman.ctrl_event_parse(msg)
	local line = string.gsub(msg, '\n+$', '')
	local priority, rest = string.match(line, '^<(%d)>(.*)$')
	if rest == nil then
		priority, rest = nil, line
	end
	local name, tail = string.match(rest, '^(%S+)%s*(.*)$')
	if name == nil then
		return nil
	end

	local event = {
		event = name,
		priority = priority and tonumber(priority) or nil,
		fields = {},
		raw = rest,
		timestamp = socket.gettime(),
	}
	local address = string.match(tail, '^(%x%x:%x%x:%x%x:%x%x:%x%x:%x%x)')
	if address ~= nil then
		event['address'] = string.lower(address)
	end
	for key, value in string.gmatch(tail, '([%w_%-]+)=(%S+)') do
		event['fields'][key] = value
	end

	return event
end

function apman.ctrl_event_wanted(name)
	return apman.ctrl_event_all or apman.ctrl_event_allow[name] == true
end

-- read whatever is queued on a monitor socket and forward it
function apman.ctrl_monitor_read(iface)
	local monitor = apman.ctrl_monitors[iface]
	if monitor == nil then
		return
	end
	for _ = 1, 32 do
		local msg = monitor.sock:receive(8192)
		if msg == nil then
			return
		end
		local event = apman.ctrl_event_parse(msg)
		-- A station that (re)associates may have used a different key than the
		-- one we cached for it, and the cached entry would otherwise stand for
		-- up to sta_ctrl_interval seconds. Dropping it here is what keeps the
		-- reported identity honest: the next status cycle asks hostapd again.
		if event ~= nil and event['address'] ~= nil
				and (event['event'] == 'AP-STA-CONNECTED'
					or event['event'] == 'AP-STA-DISCONNECTED') then
			local cache = apman.sta_ctrl_cache[iface]
			if cache ~= nil then
				cache[event['address']] = nil
			end
		end
		if event ~= nil and apman.ctrl_event_wanted(event['event']) then
			event['ifname'] = iface
			apman.publish_mqtt(
				apman.ap_topic('notifications/hostapd/' .. iface .. '/ctrl/' .. event['event']),
				cjson.encode(event))
		end
	end
end

-- Sockets of an earlier run of this agent. The file name carries the pid, so a
-- restart leaves one orphan per bss behind — harmless, but they pile up in the
-- directory hostapd uses and it keeps sending to them until the writes fail.
function apman.ctrl_cleanup_stale()
	if apman.pid == nil then
		return
	end
	os.execute(string.format(
		"for f in %s/apman-*; do case \"$f\" in *-%d-*) ;; *) rm -f \"$f\";; esac; done 2>/dev/null",
		apman.ctrl_dir, apman.pid))
end

-- attach to one bss; the reply socket has to live where the ujail can write
function apman.ctrl_monitor_attach(iface)
	if apman.ctrl_monitors[iface] ~= nil then
		return true
	end
	if not apman.ctrl_events or not apman.ctrl_enabled or not have_unix then
		return false
	end

	local path = string.format('%s/apman-mon-%d-%s', apman.ctrl_dir, apman.pid or 0, iface)
	os.remove(path)
	local sock = unix.dgram()
	if sock == nil then
		return false
	end
	local ok = sock:bind(path)
	if not ok then
		pcall(function() sock:close() end)
		return false
	end
	os.execute("chmod 0777 '" .. path .. "' 2>/dev/null")
	if not sock:connect(apman.ctrl_dir .. '/' .. iface) then
		pcall(function() sock:close() end)
		os.remove(path)
		return false
	end
	sock:settimeout(0)
	if not sock:send('ATTACH') then
		pcall(function() sock:close() end)
		os.remove(path)
		return false
	end

	apman.ctrl_monitors[iface] = { sock = sock, path = path }
	apman.ctrl_monitors[iface].ufd = uloop.fd_add(sock, function()
		apman.ctrl_monitor_read(iface)
	end, uloop.ULOOP_READ)
	print(string.format('Attached to the control channel of %s', iface))

	return true
end

function apman.ctrl_monitor_drop(iface)
	local monitor = apman.ctrl_monitors[iface]
	if monitor == nil then
		return
	end
	apman.ctrl_monitors[iface] = nil
	if monitor.ufd ~= nil then
		pcall(function() monitor.ufd:delete() end)
	end
	-- DETACH is a courtesy: hostapd drops a monitor that stops answering
	pcall(function() monitor.sock:send('DETACH') end)
	pcall(function() monitor.sock:close() end)
	os.remove(monitor.path)
	print(string.format('Detached from the control channel of %s', iface))
end

-- let go of every bss and take the reply sockets with us.
--
-- procd sends SIGTERM on stop and lua ends there, so without this the sockets
-- of the dying process stay in ctrl_dir until the next start sweeps them up in
-- ctrl_cleanup_stale(). They do not pile up across restarts, but they do
-- outlive the service, and hostapd is left holding a monitor that will never
-- answer again instead of being told we are going.
function apman.ctrl_shutdown()
	for iface in pairs(apman.ctrl_monitors) do
		apman.ctrl_monitor_drop(iface)
	end
end

-- Deliberately no signal handler here.
--
-- uloop.signal(callback, signum) does register on this build and returns a
-- handle, but the callback is never invoked — and registering it stops the
-- default action too, so a process with a "handler" survives SIGTERM instead
-- of dying. Measured: a test that registers for SIGTERM, gets sent SIGTERM,
-- and runs on to its own timeout. Using it would leave an agent that cannot be
-- stopped, which is a great deal worse than a few socket files.
--
-- So the sockets are removed by the init script when the service stops, and
-- ctrl_cleanup_stale() sweeps whatever survived that on the next start.

-- called whenever the bss list changed: attach to what is new, let go of what
-- disappeared. hostapd forgets its monitors when it restarts, and the same
-- bss.reload notification that triggers the ubus resubscribe brings us here.
function apman.ctrl_monitor_sync(wanted)
	if not apman.ctrl_stale_cleaned then
		apman.ctrl_stale_cleaned = true
		apman.ctrl_cleanup_stale()
	end
	if not apman.ctrl_events then
		for iface in pairs(apman.ctrl_monitors) do
			apman.ctrl_monitor_drop(iface)
		end
		return
	end
	for iface in pairs(apman.ctrl_monitors) do
		if wanted[iface] ~= true then
			apman.ctrl_monitor_drop(iface)
		end
	end
	for iface in pairs(wanted) do
		apman.ctrl_monitor_attach(iface)
	end
end

-- keep only the interesting keys of a control channel answer
function apman.ctrl_pick(values, fields)
	local out, found = {}, false
	for _, key in ipairs(fields) do
		if values[key] ~= nil then
			out[key] = values[key]
			found = true
		end
	end
	if not found then
		return nil
	end

	return out
end

-- refresh the cached MIB of a bss if it aged out; the answer lands in the
-- cache and is published with the next status message
function apman.refresh_mib(ifname)
	if apman.mib_interval <= 0 or not apman.ctrl_enabled or not have_unix then
		return
	end
	local now = socket.gettime()
	local entry = apman.mib_cache[ifname]
	if entry ~= nil and (now - entry.ts) < apman.mib_interval then
		return
	end
	-- mark first, so a slow hostapd does not collect a queue of requests
	apman.mib_cache[ifname] = { ts = now, values = entry and entry.values or nil }
	apman.ctrl_request(ifname, 'MIB', function(reply, err)
		if err ~= nil then
			return
		end
		local parsed = apman.ctrl_parse(reply)
		apman.mib_cache[ifname] = {
			ts = socket.gettime(),
			values = apman.ctrl_pick(parsed.values, apman.mib_fields),
		}
	end)
end

-- same for the per station detail, but only for stations we do not know yet
function apman.refresh_sta_ctrl(ifname, macs)
	if apman.sta_ctrl_interval <= 0 or not apman.ctrl_enabled or not have_unix then
		return
	end
	local now = socket.gettime()
	local cache = apman.sta_ctrl_cache[ifname]
	if cache == nil then
		cache = {}
		apman.sta_ctrl_cache[ifname] = cache
	end

	local present = {}
	for _, mac in ipairs(macs) do
		local key = string.lower(mac)
		present[key] = true
		local entry = cache[key]
		-- A station that has no identity yet is asked again far more often:
		-- hostapd only assigns the keyid at authentication time, so a client
		-- that just (re)joined would otherwise stay anonymous for a whole
		-- interval — which is exactly the moment somebody is watching to see
		-- whether a key they handed out works.
		local interval = apman.sta_ctrl_interval
		if entry ~= nil and (entry.values == nil or entry.values['keyid'] == nil) then
			interval = math.min(interval, apman.sta_ctrl_retry)
		end
		if entry == nil or (now - entry.ts) >= interval then
			cache[key] = { ts = now, values = entry and entry.values or nil }
			apman.ctrl_request(ifname, 'STA ' .. key, function(reply, err)
				if err ~= nil then
					return
				end
				local parsed = apman.ctrl_parse(reply)
				cache[key] = {
					ts = socket.gettime(),
					values = apman.ctrl_pick(parsed.values, apman.sta_ctrl_fields),
				}
			end)
		end
	end
	-- a station that left must not linger in the next status message
	for key in pairs(cache) do
		if not present[key] then
			cache[key] = nil
		end
	end
end

-- the cached values as they go into the status payload
function apman.sta_ctrl_values(ifname)
	local cache = apman.sta_ctrl_cache[ifname]
	if cache == nil then
		return nil
	end
	local out, found = {}, false
	for mac, entry in pairs(cache) do
		if entry.values ~= nil then
			out[mac] = entry.values
			found = true
		end
	end

	return found and out or nil
end

function apman.validate_rpc(cmd)
	if type(cmd) ~= 'table' then
		return { code = 12, message = 'payload is not an object' }
	end
	if cmd['jsonrpc'] ~= '2.0' then
		return { code = 2, message = 'jsonrpc must be "2.0"' }
	end
	if cmd['method'] ~= 'call' and cmd['method'] ~= 'ctrl' then
		return { code = 1, message = 'method must be "call" or "ctrl"' }
	end
	if type(cmd['params']) ~= 'table' then
		return { code = 2, message = 'params must be an array' }
	end
	if type(cmd['params'][2]) ~= 'string' or type(cmd['params'][3]) ~= 'string' then
		if cmd['method'] == 'ctrl' then
			return { code = 2, message = 'params must be [session, interface, command]' }
		end

		return { code = 2, message = 'params must be [session, object, method, args]' }
	end
	return nil
end

-- executes one request and always produces a response: either result plus
-- ubus_status 0, or an error object. Both are needed because a successful call
-- can legitimately return nothing (rrm_nr_set), which used to be
-- indistinguishable from a failure.
-- 'done' is only used by the asynchronous ctrl path: that one returns nil here
-- and hands the response to the callback once hostapd answered. Every other
-- request is still answered synchronously through the return value.
function apman.execute_rpc(cmd, done)
	local response = { jsonrpc = '2.0', id = cmd and cmd['id'], ts = socket.gettime() }
	local err = apman.validate_rpc(cmd)
	if err ~= nil then
		response['error'] = err
		print(string.format("rejected jsonrpc message: %s", err.message))
		return response
	end

	if cmd['method'] == 'ctrl' then
		local iface, command = cmd['params'][2], cmd['params'][3]
		print(string.format("ctrl %s: %s", iface, apman.trunc(command)))
		apman.ctrl_request(iface, command, function(reply, cerr)
			if cerr ~= nil then
				response['error'] = {
					code = cerr.code,
					message = cerr.message,
					object = iface,
					method = apman.ctrl_verb(command),
				}
				print(string.format("ctrl %s failed: %s", iface, cerr.message))
			else
				response['result'] = apman.ctrl_parse(reply)
				response['ubus_status'] = 0
				print(string.format("ctrl %s ok: %s", iface, apman.trunc(reply)))
			end
			response['ts'] = socket.gettime()
			if done ~= nil then
				done(response)
			else
				apman.publish_rpc_response(response)
			end
		end)

		return nil
	end

	local object, method, args = cmd['params'][2], cmd['params'][3], cmd['params'][4]
	if type(args) ~= 'table' then
		args = {}
	end
	-- the agent's own object: the radius keystore, one complete set per
	-- ssid, answered with the versions in force (see radius.apply_keys)
	if object == 'apman' then
		if not apman.radius_active then
			response['error'] = { code = 8, message = 'radius server not running', object = object, method = method }
		elseif method == 'keys' then
			local result, kerr = apman_radius.apply_keys(apman.radius_server, args)
			if result == nil then
				response['error'] = { code = 4, message = tostring(kerr), object = object, method = method }
			else
				response['result'] = result
				response['ubus_status'] = 0
			end
		elseif method == 'keys_status' then
			response['result'] = { versions = apman.radius_server.store.versions or {},
				source = apman.radius_server.store.source,
				keys = apman_radius.store_count(apman.radius_server.store) }
			response['ubus_status'] = 0
		else
			response['error'] = { code = 2, message = 'unknown method', object = object, method = method }
		end
		return response
	end
	print(string.format("calling %s %s with %s", object, method, apman.trunc(cjson.encode(args))))

	local result, status = apman.conn:call(object, method, args)
	if result == nil and type(status) == 'number' and status ~= 0 then
		response['error'] = {
			code = status,
			message = apman.ubus_status_text[status] or 'ubus error',
			object = object,
			method = method,
		}
		print(string.format("call %s %s failed: %s (%d)", object, method, response['error'].message, status))
	else
		response['result'] = result
		response['ubus_status'] = 0
		print(string.format("call %s %s ok: %s", object, method, apman.trunc(cjson.encode(result))))
	end
	return response
end

-- correlation topic, so several commands in flight do not overwrite each
-- other in the retained slot of the shared result topic
function apman.publish_rpc_response(response, suffix)
	local topic = apman.ap_topic('command_result' .. (suffix or ''))
	local payload = cjson.encode(response)
	-- not retained: consumers correlate through command_result/<id>, and a
	-- retained value here only hands every reconnecting consumer a stale
	-- result and loses one of two concurrent answers
	apman.publish_mqtt(topic, payload, 1, false)
	if response['id'] ~= nil then
		local id = string.gsub(tostring(response['id']), '[^%w%-_.]', '')
		if id ~= '' then
			apman.publish_mqtt(topic .. '/' .. id, payload, 1, false)
		end
	end
end

function apman.on_mqtt_message(mid, topic, payload)
	print(string.format("Received message. topic: '%s', message: '%s'", topic, apman.trunc(payload)))
	if topic == apman.ap_topic('command/bulk') then
		return apman.bulk_command(mid, topic, payload)
	end
	local ok, cmd = pcall(cjson.decode, payload)
	if not ok then
		cmd = nil
	end
	-- nil means the request is in flight and answers itself later
	local response = apman.execute_rpc(cmd)
	if response ~= nil then
		apman.publish_rpc_response(response)
	end
end

function apman.bulk_command(mid, topic, payload)
	local commands = {}
	local results = {}
	print(string.format("Received command list. topic: '%s', message: '%s'", topic, apman.trunc(payload)))
	if topic ~= apman.ap_topic('command/bulk') then
		print("msg checks fail0")
		return
	end
	local ok
	ok, commands = pcall(cjson.decode, payload)
	if not ok or type(commands) ~= 'table' or type(commands['list']) ~= "table" then
		print("no list found.")
		apman.publish_rpc_response({
			jsonrpc = '2.0',
			error = { code = 2, message = 'bulk payload needs a "list" array' },
			ts = socket.gettime(),
		}, '/bulk')
		return
	end
	-- one bad entry no longer discards the whole batch silently, every
	-- command gets its own result or error
	--
	-- A ctrl entry answers later, so the batch is published once the last
	-- one is in. Every ctrl request carries its own deadline, so a silent
	-- hostapd delays the batch but cannot lose it.
	local pending, published = 0, false
	local function publish_bulk()
		if published or pending > 0 then
			return
		end
		published = true
		apman.publish_mqtt(apman.ap_topic('command_result/bulk'),
			cjson.encode(results), 1, true)
	end

	for key, cmd in pairs(commands['list']) do
		pending = pending + 1
		local response = apman.execute_rpc(cmd, function(async)
			results[key] = async
			pending = pending - 1
			publish_bulk()
		end)
		if response ~= nil then
			results[key] = response
			pending = pending - 1
		end
	end
	publish_bulk()
end

-- retained inventory of what this agent is and can do, so the controller can
-- gate features per ap instead of guessing from firmware versions
function apman.publish_agent()
	local features = {}
	local function feature(name, enabled)
		if enabled then
			table.insert(features, name)
		end
	end
	feature('command_v2', true)
	feature('resend_suppression', true)
	feature('bss_events', apman.have_bss_events)
	feature('hostapd_status', apman.hostapd_status and apman.have_bss_events)
	feature('bss_info', apman.have_bss_events)
	feature('netifd_notifications', #apman.subscribe_objects > 0)
	feature('ubus_events', #apman.listen_events > 0)
	feature('station_dump', apman.station_dump)
	feature('survey', apman.survey_interval > 0)
	feature('assoclist_device', true)
	feature('ctrl_proxy', apman.ctrl_enabled and have_unix)
	feature('radius_psk', apman.radius_active)
	feature('mib', apman.ctrl_enabled and have_unix and apman.mib_interval > 0)
	feature('sta_ctrl', apman.ctrl_enabled and have_unix and apman.sta_ctrl_interval > 0)
	feature('ctrl_events', apman.ctrl_events and apman.ctrl_enabled and have_unix)

	local info = {
		agent = 'apman',
		version = apman.version,
		hostname = apman.hostname,
		started = apman.started_at,
		features = features,
		hostapd = { ucode = apman.have_bss_events },
		intervals = {
			status = apman.status_interval / 1000,
			wireless_republish = apman.wireless_republish,
			property_republish = apman.property_republish,
			probe = apman.probe_interval,
			survey = apman.survey_interval,
		},
	}
	apman.publish_property(apman.ap_topic('properties/agent'), cjson.encode(info),
		1, true, apman.property_republish)
end

-- per channel noise and busy time, the input a controller needs for fleet wide
-- channel planning. Rate limited, the payload is sizeable and slow moving.
function apman.publish_survey(devices)
	if apman.survey_interval <= 0 then
		return
	end
	local now = socket.gettime()
	if (now - apman.survey_last) < apman.survey_interval then
		return
	end
	apman.survey_last = now

	for key, device in pairs(devices) do
		local survey = apman.conn:call("iwinfo", "survey", { device = device })
		if type(survey) == 'table' then
			survey['device'] = device
			survey['timestamp'] = now
			apman.publish_mqtt(apman.ap_topic('survey/' .. device), cjson.encode(survey))
		end
	end
end

-- publishes only when the payload changed or the last publish is older than
-- max_age. Retained topics keep working for late subscribers, and a consumer
-- that lost its state resyncs within max_age.
function apman.publish_property(topic, payload, qos, retain, max_age)
	local last = apman.published[topic]
	if last ~= nil and last.payload == payload then
		if max_age == nil or (socket.gettime() - last.ts) < max_age then
			return true
		end
	end
	local result = apman.publish_mqtt(topic, payload, qos, retain)
	if result ~= nil then
		apman.published[topic] = { payload = payload, ts = socket.gettime() }
	end
	return result
end

function apman.publish_mqtt(topic, payload, qos, retain)
	local maxlen = 90
	-- dropping is intentional: while offline the broker cannot take anything
	-- anyway, and the next connect republishes the retained properties
	if not apman.mqtt_connected then
		return nil
	end
--	if type(payload) == 'string' then
--		if string.len(payload) > maxlen then 
--			print(string.format("Publish to mqtt topic '%s', payload: %s...", topic, string.sub(payload,0, maxlen-3)))
--		else
--			print(string.format("Publish to mqtt topic '%s', payload: %s", topic, payload))
--		end
--	else 
--		print(string.format("Publish binary payload to mqtt topic '%s'.", topic))
--	end
	return apman.client:publish(topic, payload, qos, retain)
end

-- the vlan a bss lives on itself: its wifi interface as a bridge port with
-- a pvid (netifd spells the ports "wlan1:*" in bridge-vlans). A station on
-- that vlan must not get tunnel attributes back — hostapd would only put it
-- where it already is.
function apman.refresh_radius_bss_vlans()
	local iface_map = {}
	local wireless = apman.conn:call("network.wireless", "status", {})
	if type(wireless) ~= 'table' then
		apman.radius_bss_vlans = {}
		apman.radius_bss_ifaces = {}
		return
	end
	for _, radio in pairs(wireless) do
		if type(radio) == 'table' and type(radio['interfaces']) == 'table' then
			for section, iface in pairs(radio['interfaces']) do
				if type(iface) == 'table' and iface['ifname'] ~= nil then
					local entry = iface_map[iface['ifname']]
					if entry == nil then
						-- netifd's wireless status carries the uci section
						-- name in the 'section' field; the map key is the
						-- ifname and only a fallback
						entry = { section = tostring(iface['section'] or section) }
						iface_map[iface['ifname']] = entry
					end
				if iface['network'] ~= nil then
					local st = apman.conn:call("network.interface", "status",
						{ name = iface['network'] })
					local bridge = type(st) == 'table' and st['device'] or nil
					if bridge ~= nil and bridge ~= '' then
						local dev = apman.conn:call("network.device", "status",
							{ name = bridge })
						if type(dev) == 'table' and type(dev['bridge-vlans']) == 'table' then
							for _, vlan in ipairs(dev['bridge-vlans']) do
								if type(vlan) == 'table' and vlan['id'] ~= nil
										and type(vlan['ports']) == 'table' then
									for _, port in ipairs(vlan['ports']) do
										local p = tostring(port)
										if string.match(p, '^[^:]+') == iface['ifname']
												and string.find(p, '*', 1, true) ~= nil then
											entry.vlan = vlan['id']
										end
									end
								end
							end
						end
					end
				end
				end
			end
		end
	end

	-- map the bssid of every wifi interface onto its vlan and its uci
	-- section name — the radius key store is keyed by the latter
	apman.radius_bss_vlans = {}
	apman.radius_bss_ifaces = {}
	for ifname, entry in pairs(iface_map) do
		local info = apman.conn:call("iwinfo", "info", { device = ifname })
		if type(info) == 'table' and type(info['bssid']) == 'string' then
			local bssid = info['bssid']:gsub('[^%x]', ''):lower()
			if #bssid == 12 then
				apman.radius_bss_ifaces[bssid] = entry.section
				if entry.vlan ~= nil then
					apman.radius_bss_vlans[bssid] = tostring(entry.vlan)
				end
			end
		end
	end
end

-- one 'name:up' line per wireless interface, sorted and joined: the change
-- gate for the bss map watchdog. Any interface going up or down changes the
-- string, which is all the map cares about.
function apman.radius_bss_status_digest()
	local lines = {}
	local wireless = apman.conn:call("network.wireless", "status", {})
	if type(wireless) == 'table' then
		for _, radio in pairs(wireless) do
			if type(radio) == 'table' and type(radio['interfaces']) == 'table' then
				for _, iface in pairs(radio['interfaces']) do
					if type(iface) == 'table' and iface['ifname'] ~= nil then
						lines[#lines + 1] = string.format('%s:%s',
							tostring(iface['ifname']), tostring(iface['up']))
					end
				end
			end
		end
	end
	table.sort(lines)
	return table.concat(lines, '|')
end

-- re-read the radius keys from the wireless config; a no-op when nothing
-- changed (one read plus a digest comparison).
--
-- The bss map must follow the radios themselves, not just the config: BSSes
-- that were down when the map was last built (boot churn, DFS CAC after a
-- radar event) would otherwise answer every query with 'no key' forever.
-- Every tick therefore re-checks the wireless status and rebuilds the map
-- when an interface went up or down; the digest keeps the steady state at
-- one ubus call per tick.
function apman.radius_reload()
	if apman.radius_server ~= nil then
		apman_radius.reload(apman.radius_server)
		local dig = apman.radius_bss_status_digest()
		apman.radius_bss_ticks = (apman.radius_bss_ticks or 0) + 1
		-- The status digest reacts to interfaces going up and down, but a
		-- map that was built wrong once (iwinfo hiccup at boot, radios still
		-- calibrating) can stay wrong forever because the status never
		-- changes. A full rebuild every 30 ticks (~5 min) bounds the damage.
		if dig ~= apman.radius_bss_digest or apman.radius_bss_ticks % 30 == 0 then
			apman.radius_bss_digest = dig
			apman.refresh_radius_bss_vlans()
		end
	end
end

-- 12 bare hex chars -> aa:bb:cc:dd:ee:ff, the format the controller and
-- every log reader expects; anything else passes through untouched
function apman.format_mac(hex)
	if type(hex) == 'string' and #hex == 12 then
		return hex:gsub('(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)', '%1:%2:%3:%4:%5:%6')
	end
	return hex
end

-- a radius accept/reject/drop. Accepts and rejects go to the broker, one
-- topic per bss: the controller can match the event against the bss it
-- configured, and Called-Station-Id gives us the bssid for free. The key
-- field names the wifi-station section the answer came from. Events from
-- sources that do not carry a bssid (radtest, non hostapd clients) land on
-- the bare topic. Drops (unauthenticated or malformed) only go to the log:
-- they are not trustable enough to act on and a hostile source must not be
-- able to flood the topic.
function apman.on_radius_event(event)
	-- built with plain concatenations on purpose: an and/or chain around
	-- string.format once evaluated to nil for events without a vid and
	-- killed every event (print, and with it the publish) silently
	local line = 'radius ' .. tostring(event.decision) .. ' '
		.. tostring(event.mac and apman.format_mac(event.mac) or '?')
	if event.key then line = line .. ' key=' .. tostring(event.key) end
	if event.key_source then line = line .. ' from=' .. tostring(event.key_source) end
	if event.bssid then line = line .. ' bss=' .. tostring(apman.format_mac(event.bssid)) end
	if event.ssid then line = line .. ' ssid=' .. tostring(event.ssid) end
	if event.akm then line = line .. ' akm=' .. tostring(event.akm) end
	if event.vid then
		line = line .. ' vid=' .. tostring(event.vid)
		if event.vlan_suppressed then line = line .. ' (bss vlan, not sent)' end
	end
	if event.reason then line = line .. ' (' .. tostring(event.reason) .. ')' end
	print(line)
	-- Only one key can ever be offered, so several unbound keys on one network
	-- means the ones behind the first cannot be enrolled until it binds. The
	-- access point cannot decide that; say it plainly here and let it travel
	-- to the controller in the event below.
	if event.unbound_keys ~= nil then
		print('radius-error ' .. tostring(event.unbound_keys) .. ' unbound keys on ssid='
			.. tostring(event.ssid) .. ', ' .. tostring(event.mac and apman.format_mac(event.mac) or '?')
			.. ' was offered ' .. tostring(event.key)
			.. ' — the others cannot enrol until it binds')
	end
	if event.decision == 'accept' or event.decision == 'reject' then
		local topic = apman.ap_topic('radius/auth' ..
			(event.bssid ~= nil and ('/' .. event.bssid) or ''))
		apman.publish_mqtt(topic, cjson.encode(event), 1, false)
	end
end

function apman.on_mqtt_disconnect(success, rc, str)
	print(string.format("Mqtt disconnected: %s", tostring(str)))
	apman.mqtt_connected = false
	-- reconnect promptly on the first loss, backoff grows from there
	apman.mqtt_backoff = 0
	apman.mqtt_next_attempt = socket.gettime() + apman.mqtt_backoff_next()
	return
end

function apman.getCollectdStats()
	apman.connect_ubus()
	if not apman.conn then
		error("Failed to connect to ubus")
		return 1
	end

	-- config
	if not apman.hostname then
		print("Resolving Hostname")
		result = apman.conn:call("uci", "get", {["config"] = "system",["section"] = "main",["option"] = "hostname"})
		if result == nil or result.value == nil then
			result = apman.conn:call("uci", "get", {["config"] = "system",["section"] = "@system[0]",["option"] = "hostname"})
		end
		if result.value == nil then
			print("Failed to get hostname")
			apman.conn:close()
			return 1
		end
		apman.hostname = result.value
	end


        local network_wireless_status = apman.conn:call("network.wireless", "status", {})
	local dev2radio = {}
	local radio_stats = {}
        for radio, value in pairs(network_wireless_status) do
		radio_stats[ radio ] = {}
		radio_stats[ radio ][ 'stations' ] = 0
		radio_stats[ radio ][ 'up' ] = value['up']

		if type(value['interfaces']) == 'table' then
			for interface, ifconfig in pairs(value['interfaces']) do
				if ifconfig['ifname'] ~= nil then
					dev2radio[ ifconfig['ifname'] ] = radio
				end
			end
		end
	end

        local devices = apman.conn:call("iwinfo", "devices", {})
        local slaves = {}
        local masters = {}
        for key, value in pairs(devices['devices']) do
                local i,j, masterdev
		masterdev = value
                i, j = string.find(value, '.sta')
                if i ~= nil then
                        local master = string.sub(value, 0, i-1)
                        if slaves[master] == nil then
                                slaves[master] = {}
                        end
			masterdev = master
                        table.insert(slaves[master], value)
                else
                        table.insert(masters, value)
                end
		if dev2radio[masterdev] ~= nil then
			local radio = dev2radio[masterdev]
			status = apman.conn:call("network.device", "status", {name = value})
			if type(status) == 'table' and type(status['statistics']) == 'table' then
				if type(radio_stats[radio]['statistics']) == 'nil' then
					radio_stats[radio]['statistics'] = status['statistics']
				else
					for k2, v2 in pairs(status['statistics']) do
						if radio_stats[radio]['statistics'][k2] == nil then
							radio_stats[radio]['statistics'][k2] = v2
						else
							radio_stats[radio]['statistics'][k2] = radio_stats[radio]['statistics'][k2] + v2
						end
					end
				end
			end
		end
        end

--	collectd.log_info('debug radiostats: '..cjson.encode(radio_stats))
        for key, value in pairs(masters) do
                status = apman.conn:call("hostapd."..value, "get_status", {})
		radio = dev2radio[ value ]
		if type(status) == 'table' then
			if status['airtime'] and type(status['airtime']) == 'table' then
				if status['airtime']['utilization'] ~= nil then
					local t = {
						host = apman.hostname,
						plugin = apman.collects_stats_plugin_name,
						plugin_instance = value,
						type = 'wifi_airtime',
						values = {status['airtime']['time'], status['airtime']['time_busy'], status['airtime']['utilization']}
					}
					collectd.dispatch_values(t)
					if radio ~= nil and radio_stats[radio] ~= nil then
						radio_stats[radio]['airtime'] = t.values
					end

				end
			end

			if status['dfs'] and type(status['dfs']) == 'table' then
				if type(status['dfs']['cac_seconds']) ~= nil then
					local t = {
						host = apman.hostname,
						plugin = apman.collects_stats_plugin_name,
						plugin_instance = value,
						type = 'wifi_dfs',
						values = {status['dfs']['cac_seconds'], status['dfs']['cac_seconds_left'], status['dfs']['cac_active']}
					}
					collectd.dispatch_values(t)
					if radio ~= nil and radio_stats[radio] ~= nil then
						radio_stats[radio]['dfs'] = t.values
					end
				end
			end

			if status['channel'] and status['freq'] and status['status'] then
				local chan_stat = 0
				if status['status'] == 'ENABLED' then
					chan_stat = 1
				end
				local t = {
					host = apman.hostname,
					plugin = apman.collects_stats_plugin_name,
					plugin_instance = value,
					type = 'wifi_channel',
					values = {status['channel'], status['freq'], chan_stat}
				}
				collectd.dispatch_values(t)
				if radio ~= nil and radio_stats[radio] ~= nil then
					radio_stats[radio]['wifi_channel'] = t.values
				end
			end
		end

                clients = apman.conn:call("hostapd."..value, "get_clients", {})
		if type(clients) == 'table' then
			if type(clients['clients']) == 'table' then
				for a3, b3 in pairs(clients['clients']) do
					radio_stats[radio]['stations'] = radio_stats[radio]['stations'] + 1
				end
			end

		end
        end

	for radio, stats in pairs(radio_stats) do
		if stats['airtime'] ~= nil then
			local t = {
				host = apman.hostname,
				plugin = apman.collects_stats_plugin_name,
				plugin_instance = radio,
				type = 'wifi_airtime',
				values = stats['airtime']
			}
			collectd.dispatch_values(t)
		end
		if stats['dfs'] ~= nil then
			local t = {
				host = apman.hostname,
				plugin = apman.collects_stats_plugin_name,
				plugin_instance = radio,
				type = 'wifi_dfs',
				values = stats['dfs']
			}
			collectd.dispatch_values(t)
		end
		if stats['wifi_channel'] ~= nil then
			local t = {
				host = apman.hostname,
				plugin = apman.collects_stats_plugin_name,
				plugin_instance = radio,
				type = 'wifi_channel',
				values = stats['wifi_channel']
			}
			collectd.dispatch_values(t)
		end
		if stats['stations'] ~= nil then
			local t = {
				host = apman.hostname,
				plugin = apman.collects_stats_plugin_name,
				plugin_instance = radio,
				type = 'stations',
				values = {stats['stations']}
			}
			collectd.dispatch_values(t)
		end
		if stats['statistics'] ~= nil then
			local t = {
				host = apman.hostname,
				plugin = apman.collects_stats_plugin_name,
				plugin_instance = radio,
				type = 'if_octets',
				values = {stats['statistics']['rx_bytes']%1073741824, stats['statistics']['tx_bytes']%1073741824}
			}
			collectd.dispatch_values(t)

			local t = {
				host = apman.hostname,
				plugin = apman.collects_stats_plugin_name,
				plugin_instance = radio,
				type = 'if_packets',
				values = {stats['statistics']['rx_packets'], stats['statistics']['tx_packets']}
			}
			collectd.dispatch_values(t)

			local t = {
				host = apman.hostname,
				plugin = apman.collects_stats_plugin_name,
				plugin_instance = radio,
				type = 'if_dropped',
				values = {stats['statistics']['rx_dropped'], stats['statistics']['tx_dropped']}
			}
			collectd.dispatch_values(t)

			local t = {
				host = apman.hostname,
				plugin = apman.collects_stats_plugin_name,
				plugin_instance = radio,
				type = 'if_errors',
				values = {stats['statistics']['rx_errors'], stats['statistics']['tx_errors']}
			}
			collectd.dispatch_values(t)
		end
	end

	apman.conn:close()
	return 0

end

function apman.init()
	apman.connect_ubus()
	if not apman.conn then
		error("Failed to connect to ubus")
	end

	-- config
	result = apman.conn:call("uci", "get", {["config"] = "system",["section"] = "@system[0]",["option"] = "hostname"})
	if result.value == nil then
		print("Failed to get hostname")
		os.exit(1)
	end
	apman.hostname = result.value
	result = apman.conn:call("uci", "get", {["config"] = "apman",["section"] = "main"})
	if type(result.values) ~= 'table' then
		print("Failed to get apman config")
		os.exit(1)
	end
	apman.config = result.values

	if apman.config['enabled'] ~= "1" then
		print("apman is not enabled")
		os.exit(1)
	end

	if apman.config['hostname'] ~= nil then
		apman.hostname = apman.config['hostname']
	end

	apman.started_at = socket.gettime()
	apman.apply_config()
	cjson.encode_invalid_numbers("null")

	-- start loop
	uloop.init()

	-- prepare the mqtt client, the connection is established from the timer
	apman.setup_mqtt()

	apman.timers['ubus_check'] = uloop.timer(apman.ubusCheckCallback)
	apman.timers['status'] = uloop.timer(apman.statusCallback)
	apman.timers['subscribe'] = uloop.timer(apman.subscribeCallback)
	apman.timers['mqtt'] = uloop.timer(apman.mqttCallback)

	apman.timers['ubus_check']:set(apman.ubus_check_interval)
	apman.timers['status']:set(apman.status_interval)

	-- radius server for hostapd wpa_psk_radius / sae per station psk queries
	apman.radius_apply()

	-- the controller provisions the radius server by writing /etc/config/
	-- apman; watch it so no restart is needed to pick the change up
	if (apman.radius_reload_interval or 10) > 0 then
		apman.timers['config'] = uloop.timer(apman.configCallback)
		apman.timers['config']:set(apman.radius_reload_interval * 1000)
	end

	-- first connection attempt; ubus subscription and the initial status
	-- publish follow from apman.on_mqtt_connect
	apman.mqttCallback()

	uloop.run()
end

-- start or stop the radius server to match the config; also runs when the
-- config watch picks up a change
function apman.radius_apply()
	if not have_radius then
		if apman.radius_enabled then
			print('Radius server requested but the apman-radius module is not installed.')
		end
		return
	end
	if apman.radius_enabled and apman.radius_active
		and (apman.radius_secret ~= apman.radius_server.secret
			or apman.radius_port ~= apman.radius_server.opts.port
			or apman.radius_bind ~= apman.radius_server.opts.bind) then
		-- the secret changed: keep answering with the old one would strand
		-- hostapd, so stop first and fall through to a fresh start
		apman_radius.stop(apman.radius_server)
		apman.radius_server = nil
		apman.radius_active = false
	end
	if apman.radius_enabled and not apman.radius_active then
		-- a failing start (bad socket, missing module) must never take the
		-- whole agent down — radius is an add-on, not the reason to live
		local ok, server, err = pcall(function()
			return apman_radius.start({
				port = apman.radius_port,
				bind = apman.radius_bind,
				secret = apman.radius_secret,
				wifi_config = apman.radius_wifi_config,
				keystore = apman.radius_keystore,
				reload_interval = apman.radius_reload_interval,
				-- B4: the periodic tick rebuilds the bssid map too, not
				-- just the key store — a map built wrong once (iwinfo
				-- hiccup at boot) otherwise rejects everybody forever
				tick = apman.radius_reload,
				onevent = apman.on_radius_event,
				bss_vlan = function(bssid) return apman.radius_bss_vlans[bssid] end,
				bss_iface = function(bssid) return apman.radius_bss_ifaces[bssid] end,
			})
		end)
		if not ok then
			print(string.format('Radius server failed to start: %s', tostring(server)))
			return
		end
		if server == nil then
			print(string.format('Radius server not started: %s', tostring(err)))
		else
			apman.radius_server = server
			apman.radius_active = true
			apman.refresh_radius_bss_vlans()
			print(string.format('Radius server listening on %s:%d, %d keys from %s.',
				apman.radius_bind, apman.radius_port,
				apman_radius.store_count(server.store), tostring(server.store.source)))
		end
	elseif not apman.radius_enabled and apman.radius_active then
		apman_radius.stop(apman.radius_server)
		apman.radius_server = nil
		apman.radius_active = false
		print('Radius server stopped.')
	end
end

-- re-read /etc/config/apman when it changes, so a controller that provisions
-- the radius server over uci needs no restart command to take effect
function apman.configCallback()
	if apman.timers['config'] ~= nil then
		apman.timers['config']:set(math.max(apman.radius_reload_interval, 1) * 1000)
	end
	local f = io.open('/etc/config/apman', 'r')
	local content = f and f:read('*a') or ''
	if f then f:close() end
	if content == apman.config_digest then
		return
	end
	apman.config_digest = content
	-- apply_config() reads apman.config, which init() filled once: without
	-- this re-read the change on disk would never reach the running values
	local result = apman.conn:call("uci", "get", {["config"] = "apman", ["section"] = "main"})
	if type(result) ~= 'table' or type(result.values) ~= 'table' then
		print('apman config changed but uci would not hand it over, keeping the running values')
		return
	end
	apman.config = result.values
	print('apman config changed, re-applying.')
	apman.apply_config()
	apman.radius_apply()
end

function apman.apply_config()
	apman.topic_prefix = apman.cfg('topic_prefix', apman.topic_prefix)
	if apman.topic_prefix:sub(-1) ~= '/' then
		apman.topic_prefix = apman.topic_prefix .. '/'
	end

	apman.status_interval = apman.cfg_num('status_interval', 10) * 1000
	apman.ubus_check_interval = apman.cfg_num('ubus_check_interval', 1) * 1000
	apman.ubus_settle = apman.cfg_num('ubus_settle', 5) * 1000
	apman.mqtt_loop_interval = apman.cfg_num('mqtt_loop_interval', 200)
	apman.mqtt_retry_min = apman.cfg_num('mqtt_retry_min', 2)
	apman.mqtt_retry_max = apman.cfg_num('mqtt_retry_max', 120)
	apman.ubus_check_interval_slow = apman.cfg_num('ubus_check_interval_slow', 30) * 1000
	apman.station_dump = apman.cfg_bool('station_dump', true)
	apman.command_topic_global = apman.cfg_bool('command_topic_global', true)
	apman.hostapd_status = apman.cfg_bool('hostapd_status', true)
	apman.subscribe_objects = apman.cfg_list('subscribe', apman.subscribe_objects)
	apman.listen_events = apman.cfg_list('listen_event', apman.listen_events)
	apman.property_republish = apman.cfg_num('property_republish', 300)
	apman.wireless_republish = apman.cfg_num('wireless_republish', 60)
	apman.probe_interval = apman.cfg_num('probe_interval', 10)
	apman.log_payload_len = apman.cfg_num('log_payload_len', 200)
	apman.survey_interval = apman.cfg_num('survey_interval', 300)

	apman.radius_enabled = apman.cfg_bool('radius_enabled', false)
	apman.radius_port = apman.cfg_num('radius_port', 1812)
	apman.radius_bind = apman.cfg('radius_bind', '127.0.0.1')
	apman.radius_keystore = apman.cfg('radius_keystore', '/etc/apman/keys.json')
	apman.radius_secret = apman.cfg('radius_secret', '')
	apman.radius_wifi_config = apman.cfg('radius_wifi_config', '/etc/config/wireless')
	apman.radius_reload_interval = apman.cfg_num('radius_reload_interval', 10)

	apman.ctrl_enabled = apman.cfg_bool('ctrl_enabled', true)
	apman.ctrl_allow_all = apman.cfg_bool('ctrl_allow_all', false)
	apman.ctrl_timeout = apman.cfg_num('ctrl_timeout', 3)
	apman.mib_interval = apman.cfg_num('mib_interval', 60)
	apman.sta_ctrl_interval = apman.cfg_num('sta_ctrl_interval', 300)
	apman.sta_ctrl_retry = apman.cfg_num('sta_ctrl_retry', 30)
	apman.ctrl_dir = apman.cfg('ctrl_dir', apman.ctrl_dir)
	apman.ctrl_events = apman.cfg_bool('ctrl_events', true)
	apman.ctrl_event_all = apman.cfg_bool('ctrl_event_all', false)
	for _, name in ipairs(apman.cfg_list('ctrl_event_allow', {})) do
		apman.ctrl_event_allow[string.upper(name)] = true
	end
	for _, name in ipairs(apman.cfg_list('ctrl_event_deny', {})) do
		apman.ctrl_event_allow[string.upper(name)] = nil
	end
	for _, verb in ipairs(apman.cfg_list('ctrl_allow', {})) do
		apman.ctrl_allowed[string.upper(verb)] = true
	end
	-- the reply socket name has to be unique per process and request
	local stat = io.open('/proc/self/stat')
	if stat ~= nil then
		apman.pid = tonumber(string.match(stat:read('*l') or '', '^(%d+)'))
		stat:close()
	end

	-- seed per host, otherwise every ap of a fleet draws the same backoff
	local seed = math.floor(socket.gettime() * 1000) % 2147483647
	for i = 1, #apman.hostname do
		seed = (seed + string.byte(apman.hostname, i) * i) % 2147483647
	end
	math.randomseed(seed)
	math.random()
	math.random()
end

return apman
