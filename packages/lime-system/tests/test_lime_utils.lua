local utils = require 'lime.utils'
local test_utils = require 'tests.utils'

describe('LiMe Utils tests', function()
    it('test literalize(str)', function()
        local str = 'f+o[o]?.*(,)_-%a$l^'
        assert.is.equal('f%+o%[o%]%?%.%*%(,%)_%-%%a%$l%^', utils.literalize(str))

        -- check that when replacing the original string with the literalized string
        -- the result is that all the string is replaced
        assert.is.equal('bar', string.gsub(str, utils.literalize(str), 'bar'))
    end)
end)
