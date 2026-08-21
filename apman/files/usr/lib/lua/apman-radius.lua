-- apman-radius: minimal RADIUS server answering hostapd per station PSK queries.
--
-- hostapd's wpa_psk_radius (1/2/3) and sae_password_psk modes authenticate a
-- station by asking the configured RADIUS server for its PSK at association
-- time (and, with wpa_psk_radius=3, again during the 4-way handshake). The
-- Access-Request carries the station MAC as User-Name and Calling-Station-Id,
-- the WLAN-AKM-Suite tells the PSK flavour apart (WPA-PSK vs SAE), and the
-- server answers Access-Accept with the PSK in an encrypted Tunnel-Password
-- attribute or Access-Reject.
--
-- Only the wire contract hostapd implements in
--   src/ap/ieee802_11_auth.c  (hostapd_radius_acl_query, decode_tunnel_passwords)
--   src/radius/radius.c       (radius_msg_finish_srv, radius_msg_get_tunnel_password)
-- is spoken: every request must carry a valid Message-Authenticator (HMAC-MD5
-- with the shared secret), which is also what keeps a packet from a wrong
-- secret out; anything else is dropped without an answer. The shared secret
-- has to match hostapd's auth_server_shared_secret.
--
-- The keys come from the uci wireless config, one wifi-station section per
-- station (or group of stations sharing a key) — the same sections the
-- firmware's hostapd.sh turns into the per bss psk/sae files:
--
--   config wifi-station 'anna'
--           list mac '00:11:22:33:44:55'
--           list mac 'aa:bb:cc:dd:ee:ff'
--           option key 'passphrase'
--           option vid '7'
--
-- The section name identifies the key (it shows up as 'key' in the event and
-- matches the keyid the controller knows), 'mac' is a list (absent = every
-- station, like hostapd's 00:00:00:00:00:00 wildcard), 'key' the passphrase,
-- 'vid' an optional vlan handed back to hostapd as tunnel attributes.
--
-- The config is re-read when its content changes, driven twice: apman
-- subscribes the hostapd-auth ubus object and reloads on its 'reload'
-- notification (every wifi config application), and a digest timer catches
-- everything that slips through.

local radius = {}

-------------------------------------------------------------- md5 (RFC 1321)
-- Pure Lua, arithmetic only: the device has no crypto module and none is
-- wanted as a dependency. Bitwise ops come from 16x16 nibble tables, built
-- once. All values are kept as exact integers below 2^32.

local and_tab, or_tab, xor_tab = {}, {}, {}
do
	for a = 0, 15 do
		for b = 0, 15 do
			local aa, bb, andv, orv, xorv, bit = a, b, 0, 0, 0, 1
			for _ = 1, 4 do
				local abit, bbit = aa % 2, bb % 2
				if abit + bbit == 2 then andv = andv + bit end
				if abit + bbit >= 1 then orv = orv + bit end
				if abit ~= bbit then xorv = xorv + bit end
				aa, bb = (aa - abit) / 2, (bb - bbit) / 2
				bit = bit * 2
			end
			and_tab[a * 16 + b] = andv
			or_tab[a * 16 + b] = orv
			xor_tab[a * 16 + b] = xorv
		end
	end
end

local function nibop(tab, a, b)
	local r, f = 0, 1
	for _ = 1, 8 do
		r = r + tab[(a % 16) * 16 + (b % 16)] * f
		a, b = math.floor(a / 16), math.floor(b / 16)
		f = f * 16
	end
	return r
end

local function band(a, b) return nibop(and_tab, a, b) end
local function bor(a, b) return nibop(or_tab, a, b) end
local function bxor(a, b) return nibop(xor_tab, a, b) end
local function bnot(a) return 4294967295 - a end

-- shifts stay exact: the factor is moved behind a mod so no intermediate
-- exceeds 2^53, and division by a power of two only moves the exponent
local function lshift(a, n)
	local m = 2 ^ (32 - n)
	return (a % m) * (2 ^ n)
end
local function rshift(a, n)
	return math.floor(a / (2 ^ n))
end
local function rol(a, n)
	return (lshift(a, n) + rshift(a, 32 - n)) % 4294967296
end

local K = {
	0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
	0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
	0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
	0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
	0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
	0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
	0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
	0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
	0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
	0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
	0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
	0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
	0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
	0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
	0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
	0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
}

local function md5(message)
	local len = #message

	-- padding: 0x80, zeros to 56 mod 64, then the bit length little endian
	local rem = (len + 1) % 64
	local zero = (rem <= 56) and (56 - rem) or (120 - rem)
	local bitlen = len * 8
	local low = bitlen % 4294967296
	local high = math.floor(bitlen / 4294967296)
	message = message .. string.char(0x80) .. string.rep('\0', zero) ..
		string.char(low % 256, math.floor(low / 256) % 256,
			math.floor(low / 65536) % 256, math.floor(low / 16777216),
			high % 256, math.floor(high / 256) % 256,
			math.floor(high / 65536) % 256, math.floor(high / 16777216))

	local a, b, c, d = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476

	local function F(x, y, z) return bor(band(x, y), band(bnot(x), z)) end
	local function G(x, y, z) return bor(band(x, z), band(y, bnot(z))) end
	local function H(x, y, z) return bxor(bxor(x, y), z) end
	local function I(x, y, z) return bxor(y, bor(x, bnot(z))) end
	local function FF(v, x, y, z, m, s, ac)
		return (rol((v + F(x, y, z) + m + ac) % 4294967296, s) + x) % 4294967296
	end
	local function GG(v, x, y, z, m, s, ac)
		return (rol((v + G(x, y, z) + m + ac) % 4294967296, s) + x) % 4294967296
	end
	local function HH(v, x, y, z, m, s, ac)
		return (rol((v + H(x, y, z) + m + ac) % 4294967296, s) + x) % 4294967296
	end
	local function II(v, x, y, z, m, s, ac)
		return (rol((v + I(x, y, z) + m + ac) % 4294967296, s) + x) % 4294967296
	end

	local m = {}
	for pos = 1, #message, 64 do
		for i = 0, 15 do
			local off = pos + i * 4
			m[i + 1] = message:byte(off) + message:byte(off + 1) * 256 +
				message:byte(off + 2) * 65536 + message:byte(off + 3) * 16777216
		end

		local a0, b0, c0, d0 = a, b, c, d

		-- round 1
		a = FF(a, b, c, d, m[1], 7, K[1]); d = FF(d, a, b, c, m[2], 12, K[2])
		c = FF(c, d, a, b, m[3], 17, K[3]); b = FF(b, c, d, a, m[4], 22, K[4])
		a = FF(a, b, c, d, m[5], 7, K[5]); d = FF(d, a, b, c, m[6], 12, K[6])
		c = FF(c, d, a, b, m[7], 17, K[7]); b = FF(b, c, d, a, m[8], 22, K[8])
		a = FF(a, b, c, d, m[9], 7, K[9]); d = FF(d, a, b, c, m[10], 12, K[10])
		c = FF(c, d, a, b, m[11], 17, K[11]); b = FF(b, c, d, a, m[12], 22, K[12])
		a = FF(a, b, c, d, m[13], 7, K[13]); d = FF(d, a, b, c, m[14], 12, K[14])
		c = FF(c, d, a, b, m[15], 17, K[15]); b = FF(b, c, d, a, m[16], 22, K[16])
		-- round 2
		a = GG(a, b, c, d, m[2], 5, K[17]); d = GG(d, a, b, c, m[7], 9, K[18])
		c = GG(c, d, a, b, m[12], 14, K[19]); b = GG(b, c, d, a, m[1], 20, K[20])
		a = GG(a, b, c, d, m[6], 5, K[21]); d = GG(d, a, b, c, m[11], 9, K[22])
		c = GG(c, d, a, b, m[16], 14, K[23]); b = GG(b, c, d, a, m[5], 20, K[24])
		a = GG(a, b, c, d, m[10], 5, K[25]); d = GG(d, a, b, c, m[15], 9, K[26])
		c = GG(c, d, a, b, m[4], 14, K[27]); b = GG(b, c, d, a, m[9], 20, K[28])
		a = GG(a, b, c, d, m[14], 5, K[29]); d = GG(d, a, b, c, m[3], 9, K[30])
		c = GG(c, d, a, b, m[8], 14, K[31]); b = GG(b, c, d, a, m[13], 20, K[32])
		-- round 3
		a = HH(a, b, c, d, m[6], 4, K[33]); d = HH(d, a, b, c, m[9], 11, K[34])
		c = HH(c, d, a, b, m[12], 16, K[35]); b = HH(b, c, d, a, m[15], 23, K[36])
		a = HH(a, b, c, d, m[2], 4, K[37]); d = HH(d, a, b, c, m[5], 11, K[38])
		c = HH(c, d, a, b, m[8], 16, K[39]); b = HH(b, c, d, a, m[11], 23, K[40])
		a = HH(a, b, c, d, m[14], 4, K[41]); d = HH(d, a, b, c, m[1], 11, K[42])
		c = HH(c, d, a, b, m[4], 16, K[43]); b = HH(b, c, d, a, m[7], 23, K[44])
		a = HH(a, b, c, d, m[10], 4, K[45]); d = HH(d, a, b, c, m[13], 11, K[46])
		c = HH(c, d, a, b, m[16], 16, K[47]); b = HH(b, c, d, a, m[3], 23, K[48])
		-- round 4
		a = II(a, b, c, d, m[1], 6, K[49]); d = II(d, a, b, c, m[8], 10, K[50])
		c = II(c, d, a, b, m[15], 15, K[51]); b = II(b, c, d, a, m[6], 21, K[52])
		a = II(a, b, c, d, m[13], 6, K[53]); d = II(d, a, b, c, m[4], 10, K[54])
		c = II(c, d, a, b, m[11], 15, K[55]); b = II(b, c, d, a, m[2], 21, K[56])
		a = II(a, b, c, d, m[9], 6, K[57]); d = II(d, a, b, c, m[16], 10, K[58])
		c = II(c, d, a, b, m[7], 15, K[59]); b = II(b, c, d, a, m[14], 21, K[60])
		a = II(a, b, c, d, m[5], 6, K[61]); d = II(d, a, b, c, m[12], 10, K[62])
		c = II(c, d, a, b, m[3], 15, K[63]); b = II(b, c, d, a, m[10], 21, K[64])

		a = (a + a0) % 4294967296
		b = (b + b0) % 4294967296
		c = (c + c0) % 4294967296
		d = (d + d0) % 4294967296
	end

	local function le32(x)
		return string.char(x % 256, math.floor(x / 256) % 256,
			math.floor(x / 65536) % 256, math.floor(x / 16777216))
	end
	return le32(a) .. le32(b) .. le32(c) .. le32(d)
end

local function xor_str(x, y)
	local out = {}
	for i = 1, #x do
		out[i] = string.char(bxor(x:byte(i), y:byte(i)))
	end
	return table.concat(out)
end

-- hmac-md5 (RFC 2104), key and message are raw strings
local function hmac_md5(key, message)
	if #key > 64 then
		key = md5(key)
	end
	local kp = key .. string.rep('\0', 64 - #key)
	return md5(xor_str(kp, string.rep(string.char(0x5c), 64)) ..
		md5(xor_str(kp, string.rep(string.char(0x36), 64)) .. message))
end

-- The pure lua code above is correct and costs 9 ms per hash on an ipq60xx,
-- because this lua has no bit library and every and/or/xor goes through the
-- nibble tables. One Access-Accept needs three to five hashes, which is the
-- 40-60 ms round trip hostapd reports. That matters: with macaddr_acl=2 the
-- access point stays silent until the answer is in, and the station gives up
-- on the authentication frame after three tries in ~330 ms — so those
-- milliseconds decide whether a roam is a fast transition or a full
-- reauthentication. The lua-md5 package does the same hash in 4 us.
--
-- Rebinding the locals is enough: hmac_md5 and the tunnel password encryption
-- reach them as upvalues and follow along. Kept optional on purpose, so an
-- access point that has not been updated yet still answers, only slowly.
do
	local ok, native = pcall(require, 'md5')
	if ok and type(native) == 'table' and type(native.sum) == 'function' then
		md5 = native.sum
		if type(native.exor) == 'function' then
			-- md5.exor insists on equal lengths; xor_str is called with a
			-- short tail nowhere today, but the fallback keeps it true
			local lua_xor = xor_str
			xor_str = function(x, y)
				if #x == #y then return native.exor(x, y) end
				return lua_xor(x, y)
			end
		end
		radius.native_md5 = true
	end
end

local hexdigits = '0123456789abcdef'
local function tohex(s)
	return (s:gsub('.', function(c)
		local b = c:byte()
		return hexdigits:sub(math.floor(b / 16) + 1, math.floor(b / 16) + 1) ..
			hexdigits:sub(b % 16 + 1, b % 16 + 1)
	end))
end

----------------------------------------------------------------- radius
-- attribute type numbers spoken here (RFC 2865/2868/7268)
local ATTR_USER_NAME = 1
local ATTR_CALLED_STATION_ID = 30
local ATTR_CALLING_STATION_ID = 31
local ATTR_TUNNEL_TYPE = 64
local ATTR_TUNNEL_MEDIUM_TYPE = 65
local ATTR_TUNNEL_PASSWORD = 69
local ATTR_MESSAGE_AUTHENTICATOR = 80
local ATTR_TUNNEL_PRIVATE_GROUP_ID = 81
local ATTR_WLAN_AKM_SUITE = 188

-- RFC 2868: tag byte plus a 24 bit big endian integer, as
-- radius_msg_get_vlanid() reads it
local function tunnel_int24(v)
	return string.char(0, math.floor(v / 65536) % 256,
		math.floor(v / 256) % 256, v % 256)
end

-- WLAN-AKM-Suite (RSN suite selector) values, IEEE 802.11 table 9-151
local AKM_NAMES = {
	['000fac01'] = 'WPA-802.1X',
	['000fac02'] = 'WPA-PSK',
	['000fac06'] = 'WPA-PSK-SHA256',
	['000fac08'] = 'SAE',
	['000fac09'] = 'FT-SAE',
	['000fac0f'] = 'WPA-EAP-SUITE-B',
	['000fac10'] = 'WPA-PSK-SUITE-B',
}

-- parse a RADIUS packet. Unknown attributes are skipped, including the
-- RFC 6929 extended ones hostapd may send (wire types 241-246 carry the
-- extended type in a third header byte, 249/250 a two byte length).
-- Returns nil on anything malformed.
function radius.parse(data)
	if type(data) ~= 'string' or #data < 20 then
		return nil
	end
	local length = data:byte(3) * 256 + data:byte(4)
	if length < 20 or length > #data then
		return nil
	end

	local attrs = {}
	local pos = 21
	while pos <= length do
		local atype, alen, vpos = data:byte(pos), nil, nil
		if atype >= 241 and atype <= 246 then
			if pos + 2 > length then return nil end
			alen = data:byte(pos + 1)
			vpos = pos + 3
			if alen < 3 or pos + alen - 1 > length then return nil end
		elseif atype == 249 or atype == 250 then
			if pos + 3 > length then return nil end
			alen = data:byte(pos + 1) * 256 + data:byte(pos + 2)
			vpos = pos + 4
			if alen < 4 or pos + alen - 1 > length then return nil end
		else
			if pos + 1 > length then return nil end
			alen = data:byte(pos + 1)
			vpos = pos + 2
			if alen < 2 or pos + alen - 1 > length then return nil end
		end
		attrs[#attrs + 1] = {
			type = atype,
			value = data:sub(vpos, pos + alen - 1),
			vpos = vpos,
		}
		pos = pos + alen
	end

	return {
		code = data:byte(1),
		id = data:byte(2),
		length = length,
		auth = data:sub(5, 20),
		attrs = attrs,
	}
end

-- verify the Message-Authenticator: HMAC-MD5(secret, packet) over the packet
-- with the attribute value zeroed. Requests without a valid one are dropped
-- without an answer.
function radius.verify(pkt, data, secret)
	local ma
	for _, attr in ipairs(pkt.attrs) do
		if attr.type == ATTR_MESSAGE_AUTHENTICATOR and #attr.value == 16 then
			ma = attr
		end
	end
	if ma == nil then
		return nil, 'no message-authenticator'
	end
	local zeroed = data:sub(1, ma.vpos - 1) .. string.rep('\0', 16) ..
		data:sub(ma.vpos + 16)
	if hmac_md5(secret, zeroed) ~= ma.value then
		return nil, 'message-authenticator mismatch'
	end
	return true
end

-- the station the query is about: User-Name, falling back to
-- Calling-Station-Id. hostapd sends the bare MAC in both, other sources are
-- tolerated by taking the first 12 hex characters. Called-Station-Id is
-- "<bssid>:<ssid>" (add_common_radius_attr), so the event can be attributed
-- to the bss a controller knows.
-- Returns mac, bssid (12 lowercase hex), ssid, akm name, raw suite.
function radius.station(pkt)
	local user, csid, called, suite
	for _, attr in ipairs(pkt.attrs) do
		if attr.type == ATTR_USER_NAME then
			user = attr.value
		elseif attr.type == ATTR_CALLING_STATION_ID then
			csid = attr.value
		elseif attr.type == ATTR_CALLED_STATION_ID then
			called = attr.value
		elseif attr.type == ATTR_WLAN_AKM_SUITE and #attr.value == 4 then
			suite = tohex(attr.value)
		end
	end

	local mac
	for _, v in ipairs({ user, csid }) do
		if type(v) == 'string' then
			local hex = v:gsub('[^%x]', ''):lower()
			if #hex >= 12 then
				mac = hex:sub(1, 12)
				break
			end
		end
	end

	local bssid, ssid
	if type(called) == 'string' then
		local hex = called:gsub('[^%x]', ''):lower()
		if #hex >= 12 then
			bssid = hex:sub(1, 12)
		end
		local colon = called:find(':', 1, true)
		if colon ~= nil then
			ssid = called:sub(colon + 1)
		end
	end

	return mac, bssid, ssid,
		AKM_NAMES[suite] or suite and ('0x' .. suite) or nil, suite
end

-- encrypt a Tunnel-Password value: tag, two byte salt, then the plaintext
-- ([length byte][psk], zero padded to 16) with the first block XORed against
-- MD5(secret + request authenticator + salt) and every later block against
-- MD5(secret + previous ciphertext block). This is the scheme
-- radius_msg_get_tunnel_password() decrypts.
function radius.tunnel_password(psk, secret, req_auth)
	local salt = string.char(math.random(0, 255), math.random(0, 255))
	local plain = string.char(#psk) .. psk
	local pad = (16 - (#plain % 16)) % 16
	if pad > 0 then
		plain = plain .. string.rep('\0', pad)
	end

	local cipher = {}
	local prev = md5(secret .. req_auth .. salt)
	for i = 1, #plain, 16 do
		cipher[#cipher + 1] = xor_str(prev, plain:sub(i, i + 15))
		prev = md5(secret .. cipher[#cipher])
	end

	return '\0' .. salt .. table.concat(cipher)
end

-- build a signed response (Access-Accept 2 / Access-Reject 3) to a request.
-- The Message-Authenticator is computed over the packet with the request
-- authenticator in place and the attribute value zeroed, then the response
-- authenticator MD5(code+id+length+request auth+attributes+secret) takes
-- over the authenticator field — the radius_msg_finish_srv() order.
function radius.build_response(req, code, attrs, secret)
	local chunks = {}
	for _, attr in ipairs(attrs) do
		chunks[#chunks + 1] = string.char(attr.type, #attr.value + 2) .. attr.value
	end
	local body = table.concat(chunks)
	local ma_attr = string.char(ATTR_MESSAGE_AUTHENTICATOR, 18) ..
		string.rep('\0', 16)
	local length = 20 + #body + 18

	local header = string.char(code, req.id,
		math.floor(length / 256), length % 256)
	local ma = hmac_md5(secret, header .. req.auth .. body .. ma_attr)
	local ma_val = string.char(ATTR_MESSAGE_AUTHENTICATOR, 18) .. ma
	local resp_auth = md5(header .. req.auth .. body .. ma_val .. secret)

	return header .. resp_auth .. body .. ma_val
end

-- strip uci quoting off a value: 'x', "x" or a bare word. Escapes are the
-- uci ones (backslash before the quote or a backslash).
local cjson = require('cjson')

local function readfile(path)
	local f = path and io.open(path, 'rb')
	if f == nil then
		return nil
	end
	local content = f:read('*a')
	f:close()
	return content
end

local function uci_unquote(v)
	if v:sub(1, 1) == "'" and v:sub(-1) == "'" then
		return v:sub(2, -2):gsub("\\'", "'"):gsub('\\\\', '\\')
	elseif v:sub(1, 1) == '"' and v:sub(-1) == '"' then
		return v:sub(2, -2):gsub('\\"', '"'):gsub('\\\\', '\\')
	end
	return v
end

-- the key store, read from the uci wireless config: every wifi-station
-- section becomes one key entry under each of its macs (the section name is
-- the key id), or the wildcard entry when it has no mac list. Sections
-- without a key or a mac that is no mac address are skipped and counted.
function radius.load_wireless(path)
	-- keys are stored per wireless interface (uci section name): a station
	-- asking on one SSID must never get the key of another. The lookup side
	-- maps the request's bssid to the section name (bss_iface callback).
	local store = { ifaces = {}, errors = 0, error_lines = {} }
	local lineno = 0
	local f = io.open(path, 'r')
	if f == nil then
		return store
	end

	local section_type, section_name, section_line
	local key, vid, macs, iface
	local function commit()
		if section_type ~= 'wifi-station' then
			return
		end
		if section_name == nil or section_name == '' or key == nil
				or #key < 8 or #key > 64
				or iface == nil or iface == '' then
			store.errors = store.errors + 1
			store.error_lines[#store.error_lines + 1] = string.format(
				'line %d: section %q, keylen=%d, iface=%s',
				section_line or 0, section_name or '<anonymous>',
				key and #key or -1, tostring(iface or ''))
			return
		end
		local entry = { psk = key, name = section_name }
		if vid ~= nil and vid ~= '' then
			entry.vid = vid
		end
		local bucket = radius.bucket(store, iface)
		if macs == nil or #macs == 0 then
			bucket.wildcards[#bucket.wildcards + 1] = entry
			return
		end
		for _, mac in ipairs(macs) do
			local hex = mac:gsub('[^%x]', ''):lower()
			if hex == '000000000000' then
				bucket.wildcards[#bucket.wildcards + 1] = entry
			elseif #hex == 12 then
				bucket.entries[hex] = entry
			else
				store.errors = store.errors + 1
				store.error_lines[#store.error_lines + 1] = string.format(
					'line %d: bad mac %q in section %s',
					section_line or 0, mac, section_name or '<anonymous>')
			end
		end
	end

	for line in f:lines() do
		lineno = lineno + 1
		line = line:gsub('^%s+', ''):gsub('%s+$', '')
		if line == '' or line:sub(1, 1) == '#' then
			-- skip
		elseif line:sub(1, 7) == 'config ' then
			commit()
			section_line = lineno
			section_type, section_name = line:match('^config%s+(%S+)%s+(.+)$')
			if section_type == nil then
				section_type = line:match('^config%s+(%S+)%s*$')
			end
			section_name = section_name ~= nil and uci_unquote(section_name) or nil
			key, vid, macs, iface = nil, nil, nil, nil
		else
			local kind, what, value = line:match('^(%S+)%s+(%S+)%s+(.+)$')
			if kind ~= nil and section_type == 'wifi-station' then
				value = uci_unquote(value)
				if what == 'key' then
					key = value
				elseif what == 'vid' then
					vid = value
				elseif what == 'mac' and (kind == 'list' or kind == 'option') then
					macs = macs or {}
					macs[#macs + 1] = value
				elseif what == 'iface' and (kind == 'list' or kind == 'option') then
					if iface == nil then
						iface = value
					end
				end
			end
		end
	end
	commit()
	f:close()
	return store
end

function radius.bucket(store, iface)
	local bucket = store.ifaces[iface]
	if bucket == nil then
		bucket = { entries = {}, wildcards = {} }
		store.ifaces[iface] = bucket
	end
	return bucket
end

-- The key store as the controller ships it: one complete, versioned key set
-- per ssid, written to opts.keystore by radius.apply_keys(). It replaces the
-- wifi-station sections (and with them wpa_psk_file/sae_password_file, which
-- wifi-scripts only renders when such sections exist) — hostapd then takes
-- every key from the Access-Accept, for WPA2 and SAE alike.
--
--   { "ssids": { "<ssid>": { "version": 12, "ifaces": ["<wifi-iface section>", ...],
--       "network_key": "optional passphrase offered to unknown stations",
--       "keys": [ { "name": "ppsk_<ssid id>_<row id>", "mac": "aabbccddeeff" | null,
--                   "psk": "...", "vid": "7" | null }, ... ] } } }
function radius.read_keystore(path)
	local content = readfile(path)
	if content == nil then
		return nil
	end
	local ok, data = pcall(cjson.decode, content)
	if not ok or type(data) ~= 'table' or type(data.ssids) ~= 'table' then
		return nil
	end
	return data
end

function radius.load_keystore(data)
	local store = { ifaces = {}, errors = 0, error_lines = {}, versions = {} }
	for ssid, set in pairs(data.ssids) do
		store.versions[ssid] = set.version
		local ifaces = type(set.ifaces) == 'table' and set.ifaces or {}
		for _, iface in ipairs(ifaces) do
			local bucket = radius.bucket(store, iface)
			bucket.ssid = ssid
			-- hostapd does not send WLAN-AKM-Suite in the mac acl
			-- query (measured: akm=nil for both psk and sae bss), so
			-- whether this network speaks SAE has to come from the
			-- controller, which knows the encryption
			bucket.sae = set.sae and true or false
			if type(set.network_key) == 'string' and #set.network_key >= 8 then
				bucket.network_key = set.network_key
			end
			for _, k in ipairs(type(set.keys) == 'table' and set.keys or {}) do
				local psk = type(k.psk) == 'string' and k.psk or ''
				if #psk < 8 or #psk > 64 or type(k.name) ~= 'string' then
					store.errors = store.errors + 1
					store.error_lines[#store.error_lines + 1] = string.format(
						'%s: key %s unusable (len %d)', ssid, tostring(k.name), #psk)
				else
					local entry = { psk = psk, name = k.name }
					if k.vid ~= nil and k.vid ~= cjson.null and tostring(k.vid) ~= '' then
						entry.vid = tostring(k.vid)
					end
					local mac = type(k.mac) == 'string' and k.mac:gsub('[^%x]', ''):lower() or ''
					if #mac == 12 and mac ~= '000000000000' then
						bucket.entries[mac] = entry
					else
						bucket.wildcards[#bucket.wildcards + 1] = entry
					end
				end
			end
		end
	end
	return store
end

-- Both sources merged, the keystore winning for the interfaces it names.
-- Not either/or on purpose: an access point carries migrated networks (keys
-- from the controller's keystore) next to ones that still keep their keys in
-- wifi-station sections, and a keystore for one ssid must never blank out
-- the others.
function radius.load_store(opts)
	local store = radius.load_wireless(opts.wifi_config)
	store.source = 'wireless'
	local data = radius.read_keystore(opts.keystore)
	if data ~= nil then
		local ks = radius.load_keystore(data)
		store.source = 'keystore+wireless'
		store.versions = ks.versions
		for iface, bucket in pairs(ks.ifaces) do
			store.ifaces[iface] = bucket
		end
		store.errors = store.errors + ks.errors
		for _, line in ipairs(ks.error_lines) do
			store.error_lines[#store.error_lines + 1] = line
		end
	end
	return store
end

-- merge one ssid's set into the keystore file (tmp + rename), rebuild the
-- store from it and answer with the versions now in force. payload is the
-- per-ssid object from the format above plus its "ssid" name; a payload
-- with keys == null removes the ssid.
function radius.apply_keys(server, payload)
	if type(payload) ~= 'table' or type(payload.ssid) ~= 'string' or payload.ssid == '' then
		return nil, 'ssid missing'
	end
	local path = server.opts.keystore
	if path == nil or path == '' then
		return nil, 'radius_keystore not set'
	end
	local data = radius.read_keystore(path) or { ssids = {} }
	if payload.keys == nil or payload.keys == cjson.null then
		data.ssids[payload.ssid] = nil
	else
		data.ssids[payload.ssid] = {
			version = payload.version,
			ifaces = payload.ifaces,
			sae = payload.sae,
			network_key = payload.network_key,
			keys = payload.keys,
		}
	end
	local dir = path:match('^(.*)/[^/]+$')
	if dir ~= nil then
		os.execute(string.format("mkdir -p '%s'", dir))
	end
	local f, err = io.open(path .. '.tmp', 'w')
	if f == nil then
		return nil, 'cannot write keystore: ' .. tostring(err)
	end
	f:write(cjson.encode(data))
	f:close()
	-- the file carries secrets; keep it to root before it gets its name
	os.execute(string.format("chmod 600 '%s.tmp' && mv '%s.tmp' '%s'", path, path, path))
	-- rebuilt through the merge, so the ssids that still keep their keys in
	-- wifi-station sections keep answering
	local store = radius.load_store(server.opts)
	server.store = store
	server.store_digest = nil
	print(string.format('radius keystore: %s at version %s, %d keys in store (%s)',
		payload.ssid, tostring(payload.version), radius.store_count(store), store.source))
	return { versions = store.versions or {}, keys = radius.store_count(store),
		errors = store.error_lines }
end

function radius.store_count(store)
	local n = 0
	for _, bucket in pairs(store.ifaces) do
		n = n + #bucket.wildcards
		for _ in pairs(bucket.entries) do
			n = n + 1
		end
	end
	return n
end

-- process one datagram: verify, decide, answer, report.
function radius.handle(server, data, ip, port)
	local function report(event)
		if server.opts.onevent ~= nil then
			-- the answer is already written: a hiccup in the event sink
			-- (mqtt reconnect, serialisation) must not kill the server
			local ok, err = pcall(server.opts.onevent, event)
			if not ok then
				-- diagnostic: the caller discards this, so a failing
				-- event sink stays invisible without it
				local df = io.open('/tmp/radius-events.log', 'a')
				if df then
					df:write(string.format('onevent error: %s\n', tostring(err)))
					df:close()
				end
			end
		end
	end

	local pkt = radius.parse(data)
	if pkt == nil or pkt.code ~= 1 then
		server.stats.dropped = server.stats.dropped + 1
		return report({
			decision = 'drop',
			reason = pkt == nil and 'malformed packet' or 'not an access-request',
			src = ip,
			ts = server.gettime(),
		})
	end

	local ok, reason = radius.verify(pkt, data:sub(1, pkt.length), server.secret)
	if not ok then
		server.stats.dropped = server.stats.dropped + 1
		return report({
			decision = 'drop',
			reason = reason,
			src = ip,
			ts = server.gettime(),
		})
	end

	local mac, bssid, ssid, akm, suite = radius.station(pkt)
	-- resolve the wireless interface the request came from and look the key
	-- up inside it only: a station asking on one SSID must never get the key
	-- of another (the wildcard of the wrong SSID was answering fleet wide)
	local iface = nil
	if bssid ~= nil and server.opts.bss_iface ~= nil then
		iface = server.opts.bss_iface(bssid)
	end
	local bucket = iface ~= nil and server.store.ifaces[iface] or nil

	-- Candidates, most specific first: the station's own key, or every
	-- wildcard key plus the network passphrase. SAE needs a passphrase —
	-- a 64 hex raw psk (wps) is only a key for WPA2, so it is left out
	-- there rather than handed to a station that cannot use it.
	local sae = suite == '000fac08' or suite == '000fac09'
		or (bucket ~= nil and bucket.sae == true)
	local candidates = {}
	local function usable(e)
		return e ~= nil and not (sae and #e.psk == 64 and e.psk:match('^%x+$'))
	end
	if mac ~= nil and bucket ~= nil then
		if usable(bucket.entries[mac]) then
			candidates[1] = bucket.entries[mac]
		else
			for _, e in ipairs(bucket.wildcards) do
				if usable(e) then
					candidates[#candidates + 1] = e
				end
			end
		end
		if bucket.network_key ~= nil and #candidates < 8 then
			local seen = false
			for _, e in ipairs(candidates) do
				if e.psk == bucket.network_key then seen = true end
			end
			if not seen then
				candidates[#candidates + 1] = { psk = bucket.network_key, name = 'network' }
			end
		end
	end
	local entry = candidates[1]

	-- TEMPORARY DEBUG — log the psk that is being delivered (phone SAE
	-- investigation)
	if entry ~= nil then
		local from = bucket.entries[mac] == entry and 'per-mac' or 'wildcard'
		print(string.format('radius-debug psk=%s from=%s n=%d mac=%s bssid=%s ssid=%s akm=%s',
			entry.psk, from, #candidates, mac or '-', bssid or '-', ssid or '-', tostring(akm)))
	end

	local own_vlan, answered_vlan, vlan_suppressed
	local code, attrs = 3, {}
	if entry ~= nil then
		code = 2
		-- least specific first in the packet: hostapd prepends every
		-- Tunnel-Password to the station's list, so the last attribute is
		-- the first key it tries — and with SAE the only one it tries
		for i = #candidates, 1, -1 do
			attrs[#attrs + 1] = {
				type = ATTR_TUNNEL_PASSWORD,
				value = radius.tunnel_password(candidates[i].psk, server.secret, pkt.auth),
			}
		end
		-- the vlan trio radius_msg_get_vlanid() decodes back — unless the
		-- station lives on the bss's own vlan, then hostapd would only put
		-- it back where it already is
		if entry.vid ~= nil and bssid ~= nil and server.opts.bss_vlan ~= nil then
			own_vlan = server.opts.bss_vlan(bssid)
		end
		if entry.vid ~= nil and own_vlan ~= entry.vid then
			attrs[#attrs + 1] = { type = ATTR_TUNNEL_TYPE, value = tunnel_int24(13) }
			attrs[#attrs + 1] = { type = ATTR_TUNNEL_MEDIUM_TYPE, value = tunnel_int24(6) }
			attrs[#attrs + 1] = { type = ATTR_TUNNEL_PRIVATE_GROUP_ID,
				value = '\0' .. entry.vid }
			answered_vlan = entry.vid
		elseif entry.vid ~= nil then
			vlan_suppressed = true
		end
	end

	server.sock:sendto(radius.build_response(pkt, code, attrs, server.secret),
		ip, port)

	if code == 2 then
		server.stats.accepted = server.stats.accepted + 1
	else
		server.stats.rejected = server.stats.rejected + 1
	end
	report({
		decision = code == 2 and 'accept' or 'reject',
		reason = entry == nil and 'no key for this station' or nil,
		mac = mac,
		bssid = bssid,
		ssid = ssid,
		akm = akm,
		akm_suite = suite,
		key = entry and entry.name or nil,
		candidates = #candidates > 1 and #candidates or nil,
		vid = entry and entry.vid or nil,
		vlan = answered_vlan or nil,
		vlan_suppressed = vlan_suppressed or nil,
		src = ip,
		ts = server.gettime(),
	})
end

-- drain whatever is queued on the socket, capped like the control channel
-- monitors so a burst cannot starve the rest of the uloop
function radius.step(server)
	for _ = 1, 32 do
		local data, ip, port = server.sock:receivefrom(4096)
		if data == nil then
			return
		end
		radius.handle(server, data, ip, port)
	end
end

-- re-read the store when the config content changed; the digest keeps the
-- common unchanged case to one read and one md5 per check. Returns true when
-- the store was replaced (the caller refreshes its bss vlan map then).
function radius.reload(server)
	-- uloop timers are one-shot: without re-arming, the digest would run
	-- exactly once after the start and every later key change made through
	-- the uci command line (no hostapd-auth event) would go unnoticed
	if server.timer ~= nil then
		server.timer:set((server.opts.reload_interval or 10) * 1000)
	end
	-- Both files are watched: apply_keys() loads the keystore right away,
	-- but a key change made through the uci command line (or a keystore
	-- written by hand) has no event and would go unnoticed otherwise.
	local content = readfile(server.opts.wifi_config)
	if content == nil then
		return false
	end
	local digest = tohex(md5(content .. '\0' ..
		(readfile(server.opts.keystore) or '')))
	if digest == server.store_digest then
		return false
	end
	local next_store = radius.load_store(server.opts)
	-- bad sections are skipped one by one (the loaders count them); an
	-- empty result on top of a filled store is the torn write case
	if radius.store_count(next_store) == 0 and radius.store_count(server.store) > 0 then
		print('radius key sources unreadable right now, keeping the previous store')
		return false
	end
	for i, detail in ipairs(next_store.error_lines) do
		if i > 5 then
			print(string.format('radius bad section: ... and %d more', #next_store.error_lines - 5))
			break
		end
		print('radius bad section (skipped): ' .. detail)
	end
	server.store_digest = digest
	server.store = next_store
	print(string.format('radius keys reloaded: %d keys (%s)',
		radius.store_count(server.store), next_store.source))
	return true
end

-- start the server on udp/1812 (or opts.port), bound to every address, never
-- blocking the uloop. Requires opts.secret and opts.wifi_config;
-- opts.onevent receives accept/reject/drop reports, opts.reload_interval is
-- the config re-read timer in seconds (0 disables it).
function radius.start(opts)
	local socket = require('socket')
	local uloop = require('uloop')

	if opts == nil or opts.secret == nil or opts.secret == '' then
		return nil, 'radius_secret not set'
	end
	if opts.wifi_config == nil or opts.wifi_config == '' then
		return nil, 'radius_wifi_config not set'
	end

	local sock = socket.udp()
	sock:setoption('reuseaddr', true)
	-- LuaSocket udp objects have no bind() — binding goes through
	-- setsockname (verified on the fleet's LuaSocket build)
	-- loopback unless told otherwise: hostapd asks at 127.0.0.1, and every
	-- packet from elsewhere would cost a pure lua hmac in the main loop
	local ok, err = sock:setsockname(opts.bind or '127.0.0.1', opts.port or 1812)
	if not ok then
		pcall(function() sock:close() end)
		return nil, 'bind failed: ' .. tostring(err)
	end
	sock:settimeout(0)

	local server = {
		sock = sock,
		opts = opts,
		secret = opts.secret,
		store = radius.load_store(opts),
		stats = { accepted = 0, rejected = 0, dropped = 0 },
		gettime = socket.gettime,
	}
	server.store_digest = tohex(md5((readfile(opts.wifi_config) or '') .. '\0' ..
		(readfile(opts.keystore) or '')))
	server.ufd = uloop.fd_add(sock, function()
		radius.step(server)
	end, uloop.ULOOP_READ)
	if server.ufd == nil then
		pcall(function() sock:close() end)
		return nil, 'uloop fd_add failed'
	end
	if (opts.reload_interval or 10) > 0 then
		-- opts.tick lets the host hook its own periodic work (bss map
		-- refresh) onto the same timer; it must call radius.reload itself
		server.timer = uloop.timer(function()
			if opts.tick ~= nil then opts.tick() else radius.reload(server) end
		end, (opts.reload_interval or 10) * 1000)
	end

	return server
end

function radius.stop(server)
	if server.timer ~= nil then
		pcall(function() server.timer:cancel() end)
		server.timer = nil
	end
	if server.ufd ~= nil then
		pcall(function() server.ufd:delete() end)
		server.ufd = nil
	end
	pcall(function() server.sock:close() end)
end

radius.md5 = md5
radius.hmac_md5 = hmac_md5
radius.tohex = tohex

return radius
