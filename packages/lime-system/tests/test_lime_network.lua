local libuci = require 'uci'
local config = require 'lime.config'
local network = require 'lime.network'

-- disable logging in config module
config.log = function() end

uci = libuci:cursor()

describe('LiMe Network tests', function()

    it('test get_mac for loopback', function()
        assert.are.same({'00', '00', '00', '00', '00', '00'}, network.get_mac('lo'))
    end)

end)
