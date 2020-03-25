local utils = require "lime.utils"
local test_utils = require "tests.utils"
local metrics_utils = require("lime.metrics.metrics_utils")

local test_file_name = "packages/ubus-lime-metrics/files/usr/libexec/rpcd/lime-metrics"
local lime_metrics = test_utils.load_lua_file_as_function(test_file_name)

local rpcd_call = test_utils.rpcd_call

describe('lime-metrics tests #metrics', function()
    it('test list methods', function()
        local response  = rpcd_call(lime_metrics, {'list'})
        assert.is.equal('value', response.get_metrics.target)
    end)

    it('test get_last_internet_path but file does not exists', function()
        local response  = rpcd_call(lime_metrics, {'call', 'get_last_internet_path'}, "")
        assert.is.equal("error", response.status)
        assert.is.equal("1", response.error.code)
    end)

    it('test get_last_internet_path', function()
        local fake_path = '/tmp/fake_get_last_internet_path'
        stub(metrics_utils, "get_last_internet_path_filename", function () return fake_path  end)
        utils.write_file(fake_path, '[{"ip":"10.133.43.6", "hostname":"node_foo"}, {"ip":"10.0.0.1","hostname":""}]')
        local response  = rpcd_call(lime_metrics, {'call', 'get_last_internet_path'}, "")
        assert.is.equal("ok", response.status)
        assert.is.equal("10.133.43.6", response.path[1].ip)
        assert.is.equal("node_foo", response.path[1].hostname)
        assert.is.equal("10.0.0.1", response.path[2].ip)
    end)

    it('test get_gateway', function()
        local fake_path = '/tmp/fake_get_last_internet_path'
        stub(metrics_utils, "get_last_internet_path_filename", function () return fake_path  end)
        utils.write_file(fake_path, '[{"ip":"10.133.43.6", "hostname":"node_foo"}, {"ip":"10.0.0.1","hostname":"thegateway"}]')
        local response  = rpcd_call(lime_metrics, {'call', 'get_gateway'}, "")
        assert.is.equal("ok", response.status)
        assert.are.same("thegateway", response.gateway.hostname)
        assert.are.same("10.0.0.1", response.gateway.ip)
    end)

    it('test get_gateway no gateway', function()
        local fake_path = '/tmp/fake_get_last_internet_path'
        stub(metrics_utils, "get_last_internet_path_filename", function () return fake_path  end)
        utils.write_file(fake_path, '{}')
        local response  = rpcd_call(lime_metrics, {'call', 'get_gateway'}, "")
        assert.is.equal("error", response.status)
    end)

    it('test get_station_traffic of inexistent interface or inexistent station', function()
        stub(utils, "unsafe_shell", function () return ''  end)
        local response  = rpcd_call(lime_metrics, {'call', 'get_station_traffic'},
                                    '{"iface": "wlan0", "station_mac": "AA:BB:CC:DD:EE:FF"}')
        assert.is.equal("error", response.status)
        assert.is.equal("1", response.error.code)
    end)

    it('test get_station_traffic', function()
        stub(utils, "unsafe_shell", function () return cmd_out  end)
        stub(utils, "unsafe_shell", function () return '256723649\n22785424'  end)
        local response  = rpcd_call(lime_metrics, {'call', 'get_station_traffic'},
                                    '{"iface": "wlan0", "station_mac": "AA:BB:CC:DD:EE:FF"}')
        assert.is.equal("ok", response.status)
        assert.is.equal(22785424, response.tx_bytes)
        assert.is.equal(256723649, response.rx_bytes)
    end)

    it('test get_metrics no protocol', function()
        stub(utils, "unsafe_shell", function () return ''  end)
        local response  = rpcd_call(lime_metrics, {'call', 'get_metrics'},  '{"target": "nodename"}')
        assert.is.equal("error", response.status)
    end)

    it('test get_metrics no link', function()
        stub(utils, "is_installed", function (m) return m == "lime-proto-babeld" end)
        local response  = rpcd_call(lime_metrics, {'call', 'get_metrics'},  '{"target": "nodename"}')
        assert.is.equal("ok", response.status)
        assert.is.equal("100", response.loss)
        assert.is.equal(0, response.bandwidth)
    end)

    it('test get_internet_status with internet', function()
        stub(metrics_utils, "get_loss", function () return  "25" end)
        stub(metrics_utils, "is_nslookup_working", function () return  true end)
        local response  = rpcd_call(lime_metrics, {'call', 'get_internet_status'},  '')
        assert.is.equal("ok", response.status)
        assert.is.equal(true, response.IPv4.working)
        assert.is.equal(true, response.IPv6.working)
        assert.is.equal(true, response.DNS.working)
    end)

end)
