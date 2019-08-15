

local iwinfo = require('iwinfo')
local utils = require 'lime.utils'
local test_utils = require 'tests.utils'

scanlist_result = {
[1] = {
    ["encryption"] = {
        ["enabled"] = true,
        ["auth_algs"] = { },
        ["description"] = "WPA2 PSK (CCMP)",
        ["wep"] = false,
        ["auth_suites"] = { {"PSK"}} ,
        ["wpa"] = 2,
        ["pair_ciphers"] = {"CCMP"} ,
        ["group_ciphers"] = {"CCMP"} ,
        } ,
    ["quality_max"] = 70,
    ["ssid"] = "foo_ssid",
    ["channel"] = 1,
    ["signal"] = -53,
    ["bssid"] = "38:AB:C0:C1:D6:70",
    ["mode"] = "Master",
    ["quality"] = 57,
  } ,
  [2] = {
    ["encryption"] = {
        ["enabled"] = false,
        ["auth_algs"] = { } ,
        ["description"] = None,
        ["wep"] = false,
        ["auth_suites"] = { } ,
        ["wpa"] = 0,
        ["pair_ciphers"] = { } ,
        ["group_ciphers"] = { } ,
    } ,
    ["quality_max"] = 70,
    ["ssid"] = "bar_ssid",
    ["channel"] = 11,
    ["signal"] = -67,
    ["bssid"] = "C2:4A:00:BE:7B:B7",
    ["mode"] = "Master",
    ["quality"] = 43,
    } ,
}


describe('iwinfo fake tests', function()
    it('test scanlist', function()
        iwinfo.fake.set_scanlist('phy0', scanlist_result)
        local scanlist = iwinfo.nl80211.scanlist('phy0')
        assert.are.equal(scanlist, scanlist_result)

        station = iwinfo.fake.scanlist_gen_station('LibreMesh.org', 7, -47,
                                                   "aa:bb:cc:dd:ee:ff", "Ad-Hoc", 37)

        assert.is.equal('Ad-Hoc', station['mode'])
        iwinfo.fake.set_scanlist('phy1', {station})
        local scanlist = iwinfo.nl80211.scanlist('phy1')
        assert.are.same({station}, scanlist)
    end)


    it('test channel(phy)', function()
        iwinfo.fake.set_channel('phy0', 1)
        iwinfo.fake.set_channel('phy1', 48)

        assert.is.equal(1, iwinfo.nl80211.channel('phy0'))
        assert.is.equal(48, iwinfo.nl80211.channel('phy1'))
        assert.is.equal(nil, iwinfo.nl80211.channel('phy2'))
    end)

    it('test assoclist(radio)', function()
        iwinfo.fake.set_assoclist('wlan1-apname', {})

        assert.are.same({}, iwinfo.nl80211.assoclist('wlan1-apname'))

        local sta = iwinfo.fake.gen_assoc_station("HT20", "HT40", -66, 50, 10000,
                                                  300, 120)

        assert.is_false(sta.rx_vht)
        assert.is_false(sta.tx_vht)
        assert.is_false(sta.rx_ht)
        assert.is_true(sta.tx_ht)
        assert.is.equal(10000, sta.inactive)
        assert.is.equal(20, sta.rx_mhz)
        assert.is.equal(40, sta.tx_mhz)
        local assoclist = {['AA:BB:CC:DD:EE:FF'] = sta}
        iwinfo.fake.set_assoclist('wlan1-apname', assoclist)
        assert.are.same(assoclist, iwinfo.nl80211.assoclist('wlan1-apname'))

    end)

    it('test hwmodelist(radio_or_phy)', function()
        hwmodelist_n_2ghz = { ["a"] = false, ["b"] = true, ["ac"] = false, ["g"] = true, ["n"] = true,}
        hwmodelist_n_5ghz = { ["a"] = true, ["b"] = false, ["ac"] = false, ["g"] = false, ["n"] = true,}

        assert.are.same(hwmodelist_n_2ghz, iwinfo.fake.HWMODE.HW_2GHZ_N)
        assert.are.same(hwmodelist_n_5ghz, iwinfo.fake.HWMODE.HW_5GHZ_N)

        -- hwmodelist returns the same for the radios or the phys
        iwinfo.fake.set_hwmodelist('wlan0-apname', hwmodelist_n_2ghz)
        iwinfo.fake.set_hwmodelist('phy0', hwmodelist_n_2ghz)
        iwinfo.fake.set_hwmodelist('wlan1-apname', hwmodelist_n_5ghz)
        iwinfo.fake.set_hwmodelist('phy1', hwmodelist_n_5ghz)

        assert.are.same(hwmodelist_n_2ghz, iwinfo.nl80211.hwmodelist('phy0'))
        assert.are.same(hwmodelist_n_2ghz, iwinfo.nl80211.hwmodelist('wlan0-apname'))

        assert.are.same(hwmodelist_n_5ghz, iwinfo.nl80211.hwmodelist('phy1'))
        assert.are.same(hwmodelist_n_5ghz, iwinfo.nl80211.hwmodelist('wlan1-apname'))
    end)
end)
