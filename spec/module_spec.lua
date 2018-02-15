local env = require 'resty.env'

local function cleanup()
  package.loaded['apicast.module'] = nil
end

describe('module', function()
  after_each(cleanup)
  before_each(cleanup)

  describe('require', function()
    it ('takes module name from env', function()
      env.set('APICAST_MODULE', 'foobar')
      local foobar = { 'foobar' }
      package.loaded['foobar'] = foobar

      assert.equal(foobar, require('apicast.module'))
    end)

    it('calls .new on the module', function()
      env.set('APICAST_MODULE', 'foobar')
      local foobar = { 'foobar' }
      package.loaded['foobar'] = { new = function() return foobar end }

      assert.equal(foobar, require('apicast.module'))
    end)

    it('defaults to apicast', function()
      local apicast = require('apicast.policy.apicast')
      local module = require('apicast.module')

      assert.truthy(module._NAME)
      assert.same(apicast._NAME, module._NAME)
    end)
  end)
end)
