
local utils = {}

utils.assert = assert

function utils.disable_asserts()
    _G['assert'] = function(expresion, message) return expresion end
end

function utils.enable_asserts()
    _G['assert'] = utils.assert
end


return utils
