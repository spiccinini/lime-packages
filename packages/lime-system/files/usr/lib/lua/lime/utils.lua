#!/usr/bin/lua

utils = {}

local config = require("lime.config")

function utils.log(...)
	if DISABLE_LOGGING ~= nil then return end
	print(...)
end

function utils.disable_logging()
	DISABLE_LOGGING = 1
end

function utils.enable_logging()
	DISABLE_LOGGING = nil
end

function utils.split(string, sep)
	local ret = {}
	for token in string.gmatch(string, "[^"..sep.."]+") do table.insert(ret, token) end
	return ret
end

function utils.stringStarts(string, start)
   return (string.sub(string, 1, string.len(start)) == start)
end

function utils.stringEnds(string, _end)
   return ( _end == '' or string.sub( string, -string.len(_end) ) == _end)
end

function utils.hex(x)
	return string.format("%02x", x)
end

function utils.printf(fmt, ...)
	print(string.format(fmt, ...))
end

function utils.isModuleAvailable(name)
	if package.loaded[name] then 
		return true
	else
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(name)
			if type(loader) == 'function' then
				package.preload[name] = loader
				return true
			end
		end
		return false
	end
end

function utils.applyMacTemplate16(template, mac)
	for i=1,6,1 do template = template:gsub("%%M"..i, mac[i]) end
	local macid = utils.get_id(mac)
	for i=1,6,1 do template = template:gsub("%%m"..i, macid[i]) end
	return template
end

function utils.applyMacTemplate10(template, mac)
	for i=1,6,1 do template = template:gsub("%%M"..i, tonumber(mac[i], 16)) end
	local macid = utils.get_id(mac)
	for i=1,6,1 do template = template:gsub("%%m"..i, tonumber(macid[i], 16)) end
	return template
end

function utils.applyHostnameTemplate(template)
	local system = require("lime.system")
	return template:gsub("%%H", system.get_hostname())
end

function utils.get_id(input)
	assert(input ~= nil, 'get_id must receive a non nil input')
	if type(input) == "table" then
		input = table.concat(input, "")
	end
	local id = {}
	local fd = io.popen('echo "' .. input .. '" | md5sum')
	if fd then
		local md5 = fd:read("*a")
		local j = 1
		for i=1,16,1 do
			id[i] = string.sub(md5, j, j + 1)
			j = j + 2
		end
		fd:close()
	end
	return id
end

function utils.network_id()
	local network_essid = config.get("wifi", "ap_ssid")
	assert(network_essid, 'config "wifi.ap_ssid" was not found!')
	return utils.get_id(network_essid)
end

function utils.applyNetTemplate16(template)
	local netid = utils.network_id()
	for i=1,3,1 do template = template:gsub("%%N"..i, netid[i]) end
	return template
end

function utils.applyNetTemplate10(template)
	local netid = utils.network_id()
	for i=1,3,1 do template = template:gsub("%%N"..i, tonumber(netid[i], 16)) end
	return template
end


--! This function is inspired to http://lua-users.org/wiki/VarExpand
--! version: 0.0.1
--! code: Ketmar // Avalon Group
--! licence: public domain
--! expand $var and ${var} in string
--! ${var} can call Lua functions: ${string.rep(' ', 10)}
--! `$' can be screened with `\'
--! `...': args for $<number>
--! if `...' is just a one table -- take it as args
function utils.expandVars(s, ...)
	local args = {...}
	args = #args == 1 and type(args[1]) == "table" and args[1] or args;

	--! return true if there was an expansion
	local function DoExpand(iscode)
		local was = false
		local mask = iscode and "()%$(%b{})" or "()%$([%a%d_]*)"
		local drepl = iscode and "\\$" or "\\\\$"
		s = s:gsub(mask,
			function(pos, code)
				if s:sub(pos-1, pos-1) == "\\" then
					return "$"..code
				else
					was = true
					local v, err
					if iscode then
						code = code:sub(2, -2)
					else
						local n = tonumber(code)
						if n then
							v = args[n]
						else
							v = args[code]
						end
					end
					if not v then
						v, err = loadstring("return "..code)
						if not v then error(err) end
						v = v()
					end
					if v == nil then v = "" end
					v = tostring(v):gsub("%$", drepl)
					return v
				end
		end)
		if not (iscode or was) then s = s:gsub("\\%$", "$") end
		return was
	end
	repeat DoExpand(true); until not DoExpand(false)
	return s
end

function utils.sanitize_hostname(hostname)
	hostname = hostname:gsub(' ', '-')
	hostname = hostname:gsub('[^-a-zA-Z0-9]', '')
	hostname = hostname:gsub('^-*', '')
	hostname = hostname:gsub('-*$', '')
	hostname = hostname:sub(1, 32)
	return hostname
end

function utils.file_exists(name)
	local f=io.open(name,"r")
	if f~=nil then io.close(f) return true else return false end
end

function utils.is_installed(pkg)
	return utils.file_exists('/usr/lib/opkg/info/'..pkg..'.control')
end

function utils.has_value(tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

--! contact array a2 to the end of array a1
function utils.arrayConcat(a1,a2)
	for _,i in ipairs(a2) do
		table.insert(a1,i)
	end
	return a1
end

--! melt table t1 into t2, if keys exists in both tables use value of t2
function utils.tableMelt(t1, t2)
	for key, value in pairs(t2) do
		t1[key] = value
	end
	return t1
end

return utils
