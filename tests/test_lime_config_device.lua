local config = require 'lime.config'
local network = require 'lime.network'
local wireless = require 'lime.wireless'
local utils = require 'lime.utils'
local hw_detection = require 'lime.hardware_detection'
local test_utils = require 'tests.utils'


-- disable logging in config module
config.log = function() end

local uci, snapshot

local librerouter_board = test_utils.get_board('librerouter-v1')

local function setup_device()
        local defaults = io.open('./packages/lime-system/files/etc/config/lime-defaults'):read("*all")
        test_utils.write_uci_file(uci, config.UCI_DEFAULTS_NAME, defaults)

        stub(wireless, "get_phy_mac", utils.get_id)
        stub(network, "get_mac", utils.get_id)
        stub(network, "assert_interface_exists", function () return true end)

        -- copy openwrt first boot generated configs
        for _, config_name in ipairs({'network', 'wireless'}) do
            local from_file  = 'tests/devices/librerouter-v1/uci_config_' .. config_name
            local to_file = uci:get_confdir() .. '/' .. config_name
            utils.write_file(to_file, utils.read_file(from_file))
            uci:load(config_name)
        end

        local iwinfo = require 'iwinfo'
        iwinfo.fake.load_from_uci(uci)

        stub(utils, "getBoardAsTable", function () return librerouter_board end)
        table.insert(hw_detection.search_paths, 'packages/*hwd*/files/usr/lib/lua/lime/hwd/*.lua')
end


describe('LiMe Config tests #deviceconfig', function()
    it('test lime-config for a LibreRouter device #librerouter', function()
        setup_device()

        config.main()

        assert.is.equal('eth0.1', config.get('lm_hwd_openwrt_wan', 'linux_name'))
        assert.is.equal('eth0', uci:get('network', 'lm_net_eth0_babeld_dev', 'ifname'))
        assert.is.equal('17', uci:get('network', 'lm_net_eth0_babeld_dev', 'vid'))
        assert.is.equal('eth0_17', uci:get('network', 'lm_net_eth0_babeld_if', 'ifname'))

        assert.is.equal(tostring(network.MTU_ETH_WITH_VLAN),
                        uci:get('network', 'lm_net_eth0_babeld_dev', 'mtu'))

        assert.is.equal('@lm_net_wlan1_mesh', uci:get('network', 'lm_net_wlan1_mesh_babeld_dev', 'ifname'))
        assert.is.equal('17', uci:get('network', 'lm_net_wlan1_mesh_babeld_dev', 'vid'))
        assert.is_nil(uci:get('network', 'lm_net_wlan1_mesh_babeld_dev', 'mtu'))

        assert.is.equal('29', uci:get('network', 'lm_net_wlan1_mesh_batadv_dev', 'vid'))

        assert.is_nil(uci:get('network', 'globals', 'ula_prefix'))
		for _, radio in ipairs({'radio0', 'radio1', 'radio2'}) do
			assert.is.equal('0', uci:get('wireless', radio, 'disabled'))
			assert.is.equal('1', uci:get('wireless', radio, 'noscan'))
		end

		assert.is.equal('11', uci:get('wireless', 'radio0', 'channel'))
		assert.is.equal('48', uci:get('wireless', 'radio1', 'channel'))
		assert.is.equal('157', uci:get('wireless', 'radio2', 'channel'))

		assert.is.equal('HT20', uci:get('wireless', 'radio0', 'htmode'))
		assert.is.equal('HT40', uci:get('wireless', 'radio1', 'htmode'))
		assert.is.equal('HT40', uci:get('wireless', 'radio2', 'htmode'))

		assert.is.equal('100', uci:get('wireless', 'radio0', 'distance'))
		assert.is.equal('1000', uci:get('wireless', 'radio1', 'distance'))
		assert.is.equal('1000', uci:get('wireless', 'radio2', 'distance'))
    end)

    it('test lime-config for a LibreRouter device', function()

        local lime_node = [[
        config net 'eth0_static'
            option linux_name 'eth0.1' # the WAN ifc of the librerouer
            list protocols 'static'
            option static_ipv4 '10.62.99.99/16'
            option static_gateway_ipv4 '10.62.0.2'
        ]]
        test_utils.write_uci_file(uci, config.UCI_NODE_NAME, lime_node)

        setup_device()

        config.main()
        uci:commit("network")

        assert.is.equal('static', uci:get('network', 'lm_net_eth0_1_static', 'proto'))
        assert.is.equal('1', uci:get('network', 'lm_net_eth0_1_static', 'auto'))
        assert.is.equal('eth0.1', uci:get('network', 'lm_net_eth0_1_static', 'ifname'))
        assert.is.equal('10.62.99.99', uci:get('network', 'lm_net_eth0_1_static', 'ipaddr'))
        assert.is.equal('255.255.0.0', uci:get('network', 'lm_net_eth0_1_static', 'netmask'))
        assert.is.equal('10.62.0.2', uci:get('network', 'lm_net_eth0_1_static', 'gateway'))
    end)

	setup('', function()
		-- fake an empty hooksDir
        config.hooksDir = io.popen("mktemp -d"):read('*l')
	end)

	teardown('', function()
		io.popen("rm -r " .. config.hooksDir)
	end)

    before_each('', function()
        snapshot = assert:snapshot()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        snapshot:revert()
        test_utils.teardown_test_uci(uci)
    end)
end)
