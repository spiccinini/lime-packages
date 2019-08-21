#!/usr/bin/lua

local wireless = require "lime.wireless"

local ap = {}

ap.wifi_mode="ap"

function ap.setup_radio(radio, args)
--!	checks("table", "?table")
	args["network"] = "lan"
	return wireless.createBaseWirelessIface(radio, ap.wifi_mode, "name", args)
end

return ap
