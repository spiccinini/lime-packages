local libuci = require 'uci'
local config = require 'lime.config'
local network = require 'lime.network'
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'

utils.disable_logging()

local uci = libuci:cursor()

function create_board_json()
    local board_json = [[{
    "model": {
        "id": "test",
        "name": "test machine"
    },
    "network": {
        "lan": {
            "ifname": "lo",
            "protocol": "static"
        }
    }
    }]]
    local f = io.open("/tmp/board.json", "w")
    f:write(board_json)
    f:close()
end

describe('LiMe Network tests', function()

    it('test get_mac for loopback', function()
        assert.are.same({'00', '00', '00', '00', '00', '00'}, network.get_mac('lo'))
    end)

    it('test primary_interface', function()
        -- disable assertions beacause there is a check to validate
        -- that the interface really exists in the system
        test_utils.disable_asserts()
        config.set('network', 'primary_interface', 'test0')
        assert.is.equal('test0', network.primary_interface())
        test_utils.enable_asserts()
    end)

    it('test primary_interface auto', function()
        config.set('network', 'primary_interface', 'auto')
        assert.is.equal('lo', network.primary_interface())
    end)

    it('test primary_address(offset)', function()
        config.set('network', 'main_ipv4_address', '10.%N1.0.0/16')
        config.set('network', 'main_ipv6_address', '2a00:1508:0a%N1:%N200::/64')
        config.set('wifi', 'ap_ssid', 'LibreMesh.org')
        ipv4, ipv6 = network.primary_address()
        assert.is.equal('10.13.0.0', ipv4:network():string())
        assert.is.equal(16, ipv4:prefix())
        -- as 'lo' interface MAC address is 00:00:00:00:00 then
        -- the current algorithm should asign 10.13.0.0 but as it is
        -- the same as the network address then it uses the max ip
        -- address available
        assert.is.equal('10.13.255.254', ipv4:host():string())

        assert.is.equal('2a00:1508:a0d:fe00::', ipv6:network():string())
        assert.is.equal(64, ipv6:prefix())
        assert.is.equal('2a00:1508:a0d:fe00::', ipv6:host():string())
    end)

    setup('', function()
        create_board_json()
        network.OLD_BOARD_JSON_PATH = network.BOARD_JSON_PATH
        network.BOARD_JSON_PATH = "/tmp/board.json"
    end)

    teardown('', function()
        os.remove("/tmp/board.json")
        network.BOARD_JSON_PATH = network.OLD_BOARD_JSON_PATH
    end)

end)
