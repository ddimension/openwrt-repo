#!/bin/sh

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/network.sh
	. ../netifd-proto.sh
	init_proto "$@"
}

proto_ieee8021x_setup() {
	local cfg="$1"
	local iface="$2"
	local mode="ieee8021x"
	

	local wpad_config bridge
	json_get_vars wpad_config bridge

	[ -z "$wpad_config" ] && {
		echo "$cfg" "No wpad_config defined."
		proto_notify_error "$cfg" INVALID_CONFIG
		proto_block_restart "$cfg"
		return
	}

	[ -f "$wpad_config" ] || {
		echo "$cfg" "No wpad_config $wpad_config not found."
		proto_notify_error "$cfg" INVALID_CONFIG
		proto_block_restart "$cfg"
		return
	}

	[ -n "$bridge" ] && {
		# Bounded wait: netifd retries the setup, so giving up here beats
		# pinning the protocol handler to a bridge that never appears.
		local waited=0
		while ! [ -d "/sys/class/net/$bridge" ]; do
			[ "$waited" -ge 30 ] && {
				echo "$cfg" "Bridge $bridge did not appear within ${waited}s."
				proto_notify_error "$cfg" NO_BRIDGE
				return 1
			}
			echo "Waiting for bridge $bridge to come up."
			sleep 1
			waited=$((waited + 1))
		done
	}

	ubus wait_for wpa_supplicant
	if [ -n "$bridge" ]; then
		echo "Start wpa_supplicant instance for device $iface, bridge $bridge with config $wpad_config ."
		local result="$(ubus call wpa_supplicant config_add '{ "driver": "wired", "ctrl": "/var/run/wpa_supplicant", "bridge": "'$bridge'", "iface": "'$iface'", "config": "'$wpad_config'" }')"
	else
		echo "Start wpa_supplicant instance for device $iface with config $wpad_config ."
		local result="$(ubus call wpa_supplicant config_add '{ "driver": "wired", "ctrl": "/var/run/wpa_supplicant", "iface": "'$iface'", "config": "'$wpad_config'" }')"
	fi
	json_init
	json_load "$result"
	local pid
	json_get_vars pid
	if [ -z "$pid" ] || [ "$pid" -lt 1 ]; then
		echo "Failed to start wpa_supplicant instance for device $iface with config $wpad_config, result: $result."
		#proto_notify_error "$cfg" 
		return
	fi
	echo "Started wpa_supplicant instance for device $iface with config $wpad_config with pid $pid."
	proto_init_update "$iface" 1
	proto_send_update "$cfg"
	proto_run_command $cfg "/bin/sh" \
		"-c" \
		"while kill -0 $pid; do sleep 1; done"

}

proto_ieee8021x_teardown() {
	local cfg="$1"
	local iface="$2"
	echo "Shut down wpa_supplicant instance for device $iface."
	ubus -v call wpa_supplicant config_remove '{"iface":"'$iface'"}'
}

proto_ieee8021x_init_config() {
	proto_config_add_string 'wpad_config'
	proto_config_add_string 'bridge'
}


[ -n "$INCLUDE_ONLY" ] || {
	add_protocol ieee8021x
}
