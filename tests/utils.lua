local limeutils = require 'lime.utils'

local utils = {}

utils.assert = assert

function utils.disable_asserts()
    _G['assert'] = function(expresion, message) return expresion end
end

function utils.enable_asserts()
    _G['assert'] = utils.assert
end

function utils.lua_path_from_pkgname(pkgname)
    return 'packages/' .. pkgname .. '/files/usr/lib/lua/?.lua;'
end

function utils.enable_package(pkgname)
    path = utils.lua_path_from_pkgname(pkgname)
    if string.find(package.path, path) == nil then
        package.path = path .. package.path
    end
end

function utils.disable_package(pkgname, modulename)
    -- remove pkg from LUA search path
    path = utils.lua_path_from_pkgname(pkgname)
    package.path = string.gsub(package.path, limeutils.literalize(path), '')
    -- remove module from preload table
    package.preload[modulename] = nil
    package.loaded[modulename] = nil
    _G[modulename] = nil
end

return utils
