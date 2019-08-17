#!/usr/bin/lua

local ieee80211s = {}

ieee80211s.wifi_mode="mesh"

function ieee80211s.setup_radio(radio, args)
--!	checks("table", "?table")
	local wireless = require "lime.wireless"
	return wireless.createBaseWirelessIface(radio, ieee80211s.wifi_mode, nil, args)
end

return ieee80211s
