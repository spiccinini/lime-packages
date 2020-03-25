local json = require 'luci.jsonc'
local lime_utils = require 'lime.utils'

local utils = {}

function utils.get_last_internet_path_filename()
    return "/etc/last_internet_path"
end

function utils.get_last_internet_path()
    local internet_path_file = io.open(utils.get_last_internet_path_filename(), "r")
    if internet_path_file then
        local path_content = assert(internet_path_file:read("*a"), nil)
        internet_path_file:close()
        local path = json.parse(path_content) or nil
        return path
    end
    return nil
end

function utils.get_loss(host, ip_version)
    local ping_cmd = "ping"
    if ip_version then
        if ip_version == 6 then
            ping_cmd = "ping6"
        end
    end
    local shell_output = lime_utils.unsafe_shell(ping_cmd .. " -q  -i 0.1 -c4 -w2 " .. host)
    local loss = "100"
    if shell_output ~= "" then
        loss = shell_output:match("(%d*)%% packet loss")
    end
    return loss
end

function utils.is_nslookup_working()
    local shell_output = lime_utils.unsafe_shell("nslookup google.com | grep Name -A2 | grep Address")
    return shell_output ~= ""
end

return utils
