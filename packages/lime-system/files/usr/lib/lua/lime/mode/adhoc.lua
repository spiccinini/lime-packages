#!/usr/bin/lua

local adhoc = {}

adhoc.wifi_mode="adhoc"

function adhoc.setup_radio(radio, args)
--!	checks("table", "?table")
	local wireless = require "lime.wireless"
	return wireless.createBaseWirelessIface(radio, adhoc.wifi_mode, nil, args)
end

return adhoc
