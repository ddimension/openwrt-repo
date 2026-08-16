#!/usr/bin/env lua

--[[
  A demo of ubus subscriber binding. Should be run after publisher.lua
--]]

require "ubus"
require "uloop"
local cjson = require "cjson"
local socket = require("socket")
local mqtt = require("mosquitto")

local apman = {}
apman.version = '56-2'			-- keep in sync with the package Makefile
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
	local objects = apman.conn:objects()
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

	for key, value in pairs(devices['devices']) do
		local is_master = 1
		iwinfo[value] = apman.conn:call("iwinfo", "info", { device = value })
		if iwinfo[value]['mode'] ~= nil and iwinfo[value]['mode'] == 'Master (VLAN)' then
			for k2, v2 in pairs(devices['devices']) do
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
	local objects = apman.conn:objects()
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
	-- the global 'hostapd' object only exists with the ucode based hostapd;
	-- its bss.add/bss.remove/bss.reload notifications replace the poll
	apman.have_bss_events = available['hostapd'] == true

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

	-- add rrm information
	local devices = apman.conn:call("iwinfo", "devices", {})
	for key, value in pairs(devices['devices']) do
		local rrm = apman.conn:call("hostapd."..value, "rrm_nr_get_own", {})
		topic = apman.ap_topic('properties/hostapd/' .. value .. '/rrm_nr_get_own')
		-- resubscribes happen often, the neighbour report almost never
		-- changes: do not republish it every time
		apman.publish_property( topic , cjson.encode(rrm), 1, true, apman.property_republish)
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
	return true
end

function apman.get_rpc_session_ubus()
	local topic, session, opts
	session = apman.conn:call("session", "create", { timeout = 0 })
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
function apman.validate_rpc(cmd)
	if type(cmd) ~= 'table' then
		return { code = 12, message = 'payload is not an object' }
	end
	if cmd['jsonrpc'] ~= '2.0' then
		return { code = 2, message = 'jsonrpc must be "2.0"' }
	end
	if cmd['method'] ~= 'call' then
		return { code = 1, message = 'method must be "call"' }
	end
	if type(cmd['params']) ~= 'table' then
		return { code = 2, message = 'params must be an array' }
	end
	if type(cmd['params'][2]) ~= 'string' or type(cmd['params'][3]) ~= 'string' then
		return { code = 2, message = 'params must be [session, object, method, args]' }
	end
	return nil
end

-- executes one request and always produces a response: either result plus
-- ubus_status 0, or an error object. Both are needed because a successful call
-- can legitimately return nothing (rrm_nr_set), which used to be
-- indistinguishable from a failure.
function apman.execute_rpc(cmd)
	local response = { jsonrpc = '2.0', id = cmd and cmd['id'], ts = socket.gettime() }
	local err = apman.validate_rpc(cmd)
	if err ~= nil then
		response['error'] = err
		print(string.format("rejected jsonrpc message: %s", err.message))
		return response
	end

	local object, method, args = cmd['params'][2], cmd['params'][3], cmd['params'][4]
	if type(args) ~= 'table' then
		args = {}
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
	apman.publish_rpc_response(apman.execute_rpc(cmd))
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
	for key, cmd in pairs(commands['list']) do
		results[key] = apman.execute_rpc(cmd)
	end
	--print(string.format('Publish result: %s',cjson.encode(response)))
	topic = apman.ap_topic('command_result/bulk')
	apman.publish_mqtt (topic, cjson.encode(results), 1, true)
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
	-- first connection attempt; ubus subscription and the initial status
	-- publish follow from apman.on_mqtt_connect
	apman.mqttCallback()

	uloop.run()
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
