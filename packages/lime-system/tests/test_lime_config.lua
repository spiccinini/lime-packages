local config = require 'lime.config'
local utils = require 'lime.utils'
local hw_detection = require 'lime.hardware_detection'
local test_utils = require 'tests.utils'
local librerouter_board = require 'tests.devices.librerouter-v1.board'

-- disable logging in config module
config.log = function() end

local uci = nil

describe('LiMe Config tests', function()

    it('test get/set_uci_cursor', function()
        local cursor = config.get_uci_cursor()
        assert.are.equal(config.get_uci_cursor(), cursor)
        config.set_uci_cursor('foo')
        assert.is.equal('foo', config.get_uci_cursor())
        --restore cursor
        config.set_uci_cursor(cursor)
    end)


    it('test empty get', function()
        assert.is_nil(config.get('section_foo', 'option_bar'))
    end)

    it('test simple get', function()
        uci:set('lime', 'section_foo', 'type_foo')
        uci:set('lime', 'section_foo', 'option_bar', 'value')
        uci:commit('lime')
        assert.is.equal('value', config.get('section_foo', 'option_bar'))
    end)

    it('test get with fallback', function()
        assert.is.equal('fallback', config.get('section_foo', 'option_bar', 'fallback'))
    end)

    it('test get with lime-default', function()
        uci:set('lime-defaults', 'section_foo', 'type_foo')
        uci:set('lime-defaults', 'section_foo', 'option_bar3', 'default_value')
        uci:commit('lime-defaults')
        assert.is.equal('default_value', config.get('section_foo', 'option_bar3'))
    end)

    it('test get precedence of fallback and lime-default', function()
        -- lime-default wins over fallback
        uci:set('lime-defaults', 'section_foo2', 'type_foo')
        uci:set('lime-defaults', 'section_foo2', 'option_bar', 'default_value')
        uci:commit('lime-defaults')
        assert.is.equal('default_value', config.get('section_foo2', 'option_bar', 'fallback'))
    end)

    it('test get_bool', function()
        for _, value in pairs({'1', 'on', 'true', 'enabled'}) do
            uci:set('lime', 'foo', 'type')
            uci:set('lime', 'foo', 'bar', value)
            uci:commit('lime')
            assert.is_true(config.get_bool('foo', 'bar'))
        end

        for _, value in pairs({'0', 'off', 'anything', 'false'}) do
            uci:set('lime', 'foo', 'type')
            uci:set('lime', 'foo', 'bar', value)
            uci:commit('lime')
            assert.is_false(config.get_bool('foo', 'bar'))
        end
    end)

    it('test set', function()
        config.set('wlan0', 'type')
        config.set('wlan0', 'htmode', 'HT20')
        assert.is.equal('HT20', config.get('wlan0', 'htmode'))
        assert.is.equal('HT20', uci:get('lime', 'wlan0', 'htmode'))
    end)

    it('test set nonstrings', function()
        -- convert integers to strings
        config.set('wifi', 'type')
        config.set('wifi', 'foo', 1)
        assert.is.equal('1', config.get('wifi', 'foo'))

        -- convert floats to strings
        config.set('wifi', 'foo', 1.9)
        assert.is.equal('1.9', config.get('wifi', 'foo'))

        -- convert booleans to strings
        config.set('wifi', 'foo', false)
        assert.is.equal('false', config.get('wifi', 'foo'))

        config.set('wifi', 'foo', true)
        assert.is.equal('true', config.get('wifi', 'foo'))
    end)

    it('test get_all', function()
        config.set('wifi', 'type')
        config.set('wifi', 'wlan0', '0')
        config.set('wifi', 'wlan1', '1')
        assert.is.equal('0', config.get_all('wifi').wlan0)
        assert.is.equal('1', config.get_all('wifi').wlan1)
    end)

    it('test lime-config #config', function()
        config.set('system', 'lime')
        config.set('system', 'domain', 'lan')
        config.set('system', 'hostname', 'LiMe-%M4%M5%M6')
        config.set('network', 'lime')
        config.set('network', 'primary_interface', 'eth0')
        config.set('network', 'main_ipv4_address', '10.%N1.0.0/16')
        config.set('network', 'main_ipv6_address', '2a00:1508:0a%N1:%N200::/64')
        config.set('network', 'resolvers', {'4.2.2.2'})
        config.set('network', 'protocols', {'static', 'lan', 'batadv:%N1', 'babeld:17', 'ieee80211s'})
        config.set('wifi', 'lime')
        config.set('wifi', 'ap_ssid', 'LibreMesh.org')
        config.set('wifi', 'modes', {'ap', 'ieee80211s'})
        config.set('wifi', 'channel_2ghz', '11')
        config.set('wifi', 'channel_5ghz', {'157', '48'})
        uci:commit('lime')

        local iwinfo = require 'iwinfo'
        iwinfo.fake.set_hwmodelist('radio0', iwinfo.fake.HWMODE.HW_5GHZ_N)

        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'type', 'mac80211')
        uci:set('wireless', 'radio0', 'channel', '11')
        uci:set('wireless', 'radio0', 'hwmode', '11n')
        uci:set('wireless', 'radio0', 'macaddr', '01:23:45:67:89:AB')
        uci:set('wireless', 'radio0', 'htmpde', 'HT40')
        uci:set('wireless', 'radio0', 'disabled', '0')

        uci:set('wireless', 'wlan0', 'wifi-iface')
        uci:set('wireless', 'wlan0', 'device', 'radio0')
        uci:set('wireless', 'wlan0', 'network', 'lan')
        uci:set('wireless', 'wlan0', 'mode', 'ap')
        uci:set('wireless', 'wlan0', 'ssid', 'OpenWrt')
        uci:set('wireless', 'wlan0', 'encryption', 'none')
        uci:commit('wireless')

        -- copy network config
        local fin = io.open('tests/devices/librerouter-v1/uci_config_network', 'r')
        local fout = io.open(uci:get_confdir() .. '/network', 'w')
        fout:write(fin:read('*a'))
        fin:close()
        fout:close()
        uci:load('network')
        assert.is.equal('auto', uci:get('network', 'globals', 'ula_prefix'))

        -- Here is the generation of the base openwrt config:
        --    openwrt/package/base-files/files/bin/config_generate


        --stub(network, "get_mac", function () return  {'00', '00', '00', '00', '00', '00'} end)
        test_utils.disable_asserts()

        stub(utils, "getBoardAsTable", function () return librerouter_board end)
        table.insert(hw_detection.search_paths, 'packages/*hwd*/files/usr/lib/lua/lime/hwd/*.lua')

        config.hooksDir = io.popen("mktemp -d"):read('*l')

        config.main()
        test_utils.enable_asserts()

        uci:commit('lime')
        uci:commit('network')
        uci:commit('babeld')
        uci:commit('wireless')

        --local l = io.popen("cat /tmp/*/lime") -- TODO: deleteme
        --print(l:read("*a"))
        --local l = io.popen("cat /tmp/*/network") -- TODO: deleteme
        --print(l:read("*a"))
        --local l = io.popen("cat /tmp/*/babeld") -- TODO: deleteme
        --print(l:read("*a"))
        --local l = io.popen("cat /tmp/*/wireless") -- TODO: deleteme
        --print(l:read("*a"))
        assert.is.equal('eth0.1', config.get('lm_hwd_openwrt_wan', 'linux_name'))
        assert.is.equal('eth0', uci:get('network', 'lm_net_eth0_babeld_dev', 'ifname'))
        assert.is.equal('17', uci:get('network', 'lm_net_eth0_babeld_dev', 'vid'))
        assert.is.equal('eth0_17', uci:get('network', 'lm_net_eth0_babeld_if', 'ifname'))

        assert.is_nil(uci:get('network', 'globals', 'ula_prefix'))


        io.popen("rm -r " .. config.hooksDir)
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
