#!/usr/bin/lua

local wireless = require "lime.wireless"

local adhoc = {}

adhoc.wifi_mode="adhoc"

function adhoc.setup_radio(radio, args)
--!	checks("table", "?table")
	return wireless.createBaseWirelessIface(radio, adhoc.wifi_mode, nil, args)
end

return adhoc
