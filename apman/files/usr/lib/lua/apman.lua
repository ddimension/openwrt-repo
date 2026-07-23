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
apman.conn = nil
apman.hostname = nil
apman.config = {}
apman.mqtt_hostname = 'app1.kalnet.hooya.de'
apman.topic_prefix = 'apman/'
apman.client = nil
apman.count = 0
apman.timers = {}
apman.ubus_session = {}
apman.disconnected = nil
apman.collects_stats_plugin_name = 'apman'

function apman.starts_with(str, start)
	return str:sub(1, #start) == start
end

function apman.getOutput(cmd)
	local f = io.popen (cmd)
	local output = f:read("*a") or ""
	f:close()
	return output
end

function apman.createUbusCallback(object, topic)
	return {
		notify = function( msg, method )
			local ltopic = topic .. '/' .. method
			if type(msg) == 'table' then
				msg['timestamp'] = socket.gettime()
			end
			apman.publish_mqtt( ltopic, cjson.encode(msg))
			--print(string.format("Published from object '%s' to mqtt topic '%s', payload: %s", object, ltopic, cjson.encode(msg)))
		end
	}
end

function apman.mqttCallback()
	apman.client:loop(10)
	if apman.disconnected ~= nil then
		apman.disconnected = nil
		apman.client:destroy()
		apman.connect_mqtt()
	end
	apman.timers['mqtt']:set(200)
end

function apman.ubusCheckCallback()
	local c2 = 0
	local objects = apman.conn:objects()
	for key, object in pairs(objects) do
		if apman.starts_with(object, "hostapd") then
			c2 = c2 + 1
		end
	end
	if apman.count ~= c2 then
		print('Ubus object list changed, wait 5 seconds and restart ubus.')
		socket.sleep(5)
		apman.reconnect_ubus()
		apman.subscribe_ubus()
	end
	apman.timers['ubus_check']:set(1000)
end

function apman.statusCallback()
	local topic, devices, data
	local devices = apman.conn:call("iwinfo", "devices", {})
	data = {}
	data['devices'] = {}
	local iwinfo = {}
	local slaves = {}
	local masters = {}

	for key, value in pairs(devices['devices']) do
		local is_master = 1
		iwinfo[value] = apman.conn:call("iwinfo", "info", { device = value })
		if iwinfo[value]['mode'] ~= nil and iwinfo[value]['mode'] == 'Master (VLAN)' then
			for k2, v2 in pairs(devices['devices']) do
				s = v2
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
		data['devices'][value]['assoclist'] = apman.conn:call("iwinfo", "assoclist", { device = value })
		data['devices'][value]['stations'] = apman.getOutput("iw dev "..value.." station dump")
		if slaves[value] ~= nil then
			for k2, subdevice in pairs(slaves[value]) do
				--print('queried slave '..subdevice)
				data['devices'][value]['stations'] = data['devices'][value]['stations'] .. "\n" .. apman.getOutput("iw dev "..subdevice.." station dump")
			end
		end
		data['devices'][value]['status'] = apman.conn:call("network.device", "status", { name = value })
		data['devices'][value]['ap_status'] = apman.conn:call("hostapd."..value, "get_status", {})
		topic = apman.topic_prefix  ..'ap/' .. apman.hostname .. '/device/hostapd/' .. value .. '/status';
		data['devices']['timestamp'] = socket.gettime()
		apman.publish_mqtt( topic , cjson.encode(data['devices'][value]))
		--print("Published data to mqtt topic '"..topic.."'.")
	end

        topic = apman.topic_prefix  .. 'ap/' .. apman.hostname .. '/' .. 'online'
	apman.publish_mqtt(topic, cjson.encode({['status'] = 'online', ["timestamp"] = socket.gettime()}))

	data = apman.conn:call("system", "info", {})
	if type(data) == 'table' then
		data['timestamp'] = socket.gettime()
	end
	topic = apman.topic_prefix  ..'ap/' .. apman.hostname .. '/properties/system/info';
	apman.publish_mqtt( topic , cjson.encode(data))

	data = apman.conn:call("network.wireless", "status", {})
	if type(data) == 'table' then
		data['timestamp'] = socket.gettime()
	end
	topic = apman.topic_prefix  ..'ap/' .. apman.hostname .. '/wireless/status';
	apman.publish_mqtt( topic , cjson.encode(data))

	apman.timers['status']:set(10000)
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

function apman.subscribe_ubus()
	local topic, devices
	apman.count = 0
	while apman.count<1 do
		objects = apman.conn:objects()
		for key, object in pairs(objects) do
			if apman.starts_with(object, "hostapd") then
				local topic = apman.topic_prefix .. 'ap/' .. apman.hostname .. '/notifications/hostapd/' .. object:gsub('%hostapd.','')
				print(string.format("Adding subscription for object '%s', assigning to topic '%s'.", object, topic))
				apman.conn:subscribe(object, apman.createUbusCallback(object, topic))
				apman.count = apman.count + 1
			end
		end
		socket.sleep(1)	
	end

	-- add rrm information
	local devices = apman.conn:call("iwinfo", "devices", {})
	for key, value in pairs(devices['devices']) do
		local rrm = apman.conn:call("hostapd."..value, "rrm_nr_get_own", {})
		topic = apman.topic_prefix  ..'ap/' .. apman.hostname .. '/properties/hostapd/' .. value .. '/rrm_nr_get_own';
		apman.publish_mqtt( topic , cjson.encode(rrm), 1 ,true)
	end
	-- send session
	data = apman.get_rpc_session_ubus()
	if type(data) == 'table' then
		data['timestamp'] = socket.gettime()
	end
	topic = apman.topic_prefix  ..'ap/' .. apman.hostname .. '/properties/session/create';
	apman.publish_mqtt( topic , cjson.encode(data))
end

function apman.get_rpc_session_ubus()
	local topic, session, opts
	session = apman.conn:call("session", "create", { timeout = 0 })
	print(string.format("Result of session create: %s", cjson.encode(session)))

	local result
	result = apman.conn:call("session", "list", { ubus_rpc_session = session['ubus_rpc_session'] })
	print(string.format("Result of session list: %s", cjson.encode(result)))

	opts = { scope = 'file',  objects = {}, ubus_rpc_session = session['ubus_rpc_session']}
	table.insert(opts['objects'], {['/*'] = 'read'})
	table.insert(opts['objects'], {['/*'] = 'write'})
	table.insert(opts['objects'], {['/*'] = 'exec'})
	print(string.format("Opts for session grant: %s", cjson.encode(opts)))
	result = apman.conn:call("session", "grant", opts)
	print(string.format("Result of session gant: %s", cjson.encode(result)))

	result = apman.conn:call("session", "list", { ubus_rpc_session = session['ubus_rpc_session'] })
	print(string.format("Result of session list: %s", cjson.encode(result)))

	apman.session = session
	return session
end

function apman.connect_mqtt()
	local retry_timer = 5
	local topic, result, ctr, loop
	local mqtt_host, mqtt_port, mqtt_keepalive, mqtt_clientid
	local data = {}

	-- mqtt setup
	if apman.config['mqtt_clientid'] then
		apman.client = mqtt.new(apman.config['mqtt_clientid'], false)
	else
		apman.client = mqtt.new(apman.hostname, false)
	end
	-- assign MQTT client event handlers

	apman.client.ON_LOG = apman.mqtt_log

	apman.client.ON_MESSAGE = apman.on_mqtt_message
	apman.client.ON_DISCONNECT = apman.reconnect_mqtt_callback
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


	-- set last will (must be done before connection)
	topic = apman.topic_prefix  .. 'ap/' .. apman.hostname .. '/' .. 'online'
	apman.client:will_set(topic, cjson.encode({['status']='offline'}), 1, false)

	ctr = 0
	loop = true
	while loop do
		ctr = ctr + 1
		result = apman.client:connect(mqtt_host, mqtt_port, mqtt_keepalive)
		if result then
			loop = false
		else
			print("Mqtt connection failed, waiting ".. retry_timer .. "s, retry no " .. ctr .. ".")
			socket.sleep(retry_timer)
		end
	end
	apman.publish_mqtt(topic, cjson.encode({['status'] = 'online', ["timestamp"] = socket.gettime()}))

	-- subscribe command topics
	topic = apman.topic_prefix .. 'command'
	apman.client:subscribe(topic, 1)
	print("Waiting for commands on topic: ", topic)
	topic = apman.topic_prefix .. 'ap/' .. apman.hostname .. '/command'
	apman.client:subscribe(topic, 1)
	print("Waiting for commands on topic: ", topic)
	topic = apman.topic_prefix .. 'ap/' .. apman.hostname .. '/command/bulk'
	apman.client:subscribe(topic, 1)
	print("Waiting for commands on topic: ", topic)

	-- initial publish
	--- system.board
	data = apman.conn:call("system", "board", {})
	if type(data) == 'table' then
		data['timestamp'] = socket.gettime()
	end
	topic = apman.topic_prefix  ..'ap/' .. apman.hostname .. '/properties/system/board';
	apman.publish_mqtt( topic , cjson.encode(data), 1, true)
	--- system.info
	data = apman.conn:call("system", "info", {})
	if type(data) == 'table' then
		data['timestamp'] = socket.gettime()
	end
	topic = apman.topic_prefix  ..'ap/' .. apman.hostname .. '/properties/system/info';
	apman.publish_mqtt( topic , cjson.encode(data))

	apman.client:loop(100)
end

function apman.on_mqtt_message(mid, topic, payload)
	print(string.format("Received message. topic: '%s', message: '%s'", topic, payload))
	if topic == apman.topic_prefix .. 'ap/' .. apman.hostname .. '/command/bulk' then
		return apman.bulk_command(mid, topic, payload)
	end
	local cmd = cjson.decode(payload)
	if type(cmd) ~= 'table' then
		print("msg checks fail0")
		return
	end
	if cmd['jsonrpc'] == nil or  cmd['method'] == nil or cmd['params'] == nil then
		print("msg checks fail1")
		return
	end
	if cmd['jsonrpc'] ~= '2.0' or cmd['method'] ~= 'call' then
		print("msg checks fail2")
		return
	end
	if type(cmd['params']) ~= 'table' then
		print("msg checks fail3")
		return
	end
	print(string.format("received jsonrpc message. calling %s %s with %s", cmd['params'][2], cmd['params'][3], cjson.encode(cmd['params'][4])))
	local response = {}
	response['jsonrpc'] = '2.0'
	response['id'] = cmd['id']
	response['result'] = apman.conn:call(cmd['params'][2], cmd['params'][3], cmd['params'][4])
	--print(string.format('Publish result: %s',cjson.encode(response)))
	topic = apman.topic_prefix .. 'ap/' .. apman.hostname .. '/command_result'
	apman.publish_mqtt (topic, cjson.encode(response), 1, true)
end

function apman.bulk_command(mid, topic, payload)
	local commands = {}
	local results = {}
	print(string.format("Received command list. topic: '%s', message: '%s'", topic, payload))
	if topic ~= apman.topic_prefix .. 'ap/' .. apman.hostname .. '/command/bulk' then
		print("msg checks fail0")
		return
	end
	commands = cjson.decode(payload)
	if type(commands['list']) ~= "table" then
		print("no list found.")
		return
	end
	for key, cmd in pairs(commands['list']) do
		if type(cmd) ~= 'table' then
			print("msg checks fail0")
			return
		end
		if cmd['jsonrpc'] == nil or  cmd['method'] == nil or cmd['params'] == nil then
			print("msg checks fail1")
			return
		end
		if cmd['jsonrpc'] ~= '2.0' or cmd['method'] ~= 'call' then
			print("msg checks fail2")
			return
		end
		if type(cmd['params']) ~= 'table' then
			print("msg checks fail3")
			return
		end
		print(string.format("command[%s] in bulk command calling %s %s with %s", key, cmd['params'][2], cmd['params'][3], cjson.encode(cmd['params'][4])))
		local response = {}
		response['jsonrpc'] = '2.0'
		response['id'] = cmd['id']
		response['result'] = apman.conn:call(cmd['params'][2], cmd['params'][3], cmd['params'][4])
		print(string.format("response for jsonrpc message: %s", cjson.encode(response['result'])))
		results[key] = response
	end
	--print(string.format('Publish result: %s',cjson.encode(response)))
	topic = apman.topic_prefix .. 'ap/' .. apman.hostname .. '/command_result/bulk'
	apman.publish_mqtt (topic, cjson.encode(results), 1, true)
end

function apman.publish_mqtt(topic, payload, qos, retain)
	local maxlen = 90
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

function apman.reconnect_mqtt_callback()
	print("Disconnect.")
	apman.disconnected = 1
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

	cjson.encode_invalid_numbers("null")
	-- xonnect to mqtt
	apman.connect_mqtt()
	apman.subscribe_ubus()

	-- start loop
	uloop.init()

	apman.timers['ubus_check'] = uloop.timer(apman.ubusCheckCallback)
	apman.timers['ubus_check']:set(1000)

	-- inform about boot up
	apman.publish_mqtt(apman.topic_prefix .. 'ap/' .. apman.hostname .. '/booted', cjson.encode({}))
	apman.timers['status'] = uloop.timer(apman.statusCallback)
	-- initial call and setup
	apman.statusCallback()

	apman.timers['mqtt'] = uloop.timer(apman.mqttCallback)
	-- initial call and setup
	apman.mqttCallback()

	uloop.run()
end

return apman
