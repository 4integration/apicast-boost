local MappingRule = require('apicast.mapping_rule')

describe('mapping_rule', function()
  describe('.matches', function()
    it('returns true when method, URI, and args match', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('GET', '/abc', { a_param = '1' })
      assert.is_true(match)
    end)

    it('returns true when method and URI match, and no args are required', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('GET', '/abc', { a_param = '1' })
      assert.is_true(match)
    end)

    it('returns false when the method does not match', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('POST', '/abc', { a_param = '1' })
      assert.is_false(match)
    end)

    it('returns false when the URI does not match', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('GET', '/aaa', { a_param = '1' })
      assert.is_false(match)
    end)

    it('returns false when the args do not match', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('GET', '/abc', { a_param = '2' })
      assert.is_false(match)
    end)

    it('returns false when method, URI, and args do not match', function()
      local mapping_rule = MappingRule.from_proxy_rule({
        http_method = 'GET',
        pattern = '/abc',
        querystring_parameters = { a_param = '1' },
        metric_system_name = 'hits',
        delta = 1
      })

      local match = mapping_rule:matches('POST', '/def', { x = 'y' })
      assert.is_false(match)
    end)
  end)
end)
