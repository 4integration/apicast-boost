local policy = require 'apicast.policy'
local _M = require 'apicast.policy_chain'

describe('policy_chain', function()
  it('defines a method for each of the nginx phases supported', function()
    for _, phase in policy.phases() do
      assert.equals('function', type(_M[phase]))
    end
  end)

  it('when calling one of the nginx phases, calls that phase on each of its policies', function()
    -- Define a policy an stub its phase methods
    local custom_policy_1 = policy.new('policy_1')
    custom_policy_1.init = function () end
    custom_policy_1.rewrite = function() end
    stub(custom_policy_1, 'init')
    stub(custom_policy_1, 'rewrite')

    -- Define another policy and stub its phase methods
    local custom_policy_2 = policy.new('policy_2')
    custom_policy_2.init = function () end
    custom_policy_2.access = function() end
    stub(custom_policy_2, 'init')
    stub(custom_policy_2, 'access')

    -- Build the policy chain
    local chain = _M.build({ custom_policy_1, custom_policy_2 })

    chain:init()
    assert.stub(custom_policy_1.init).was_called()
    assert.stub(custom_policy_2.init).was_called()

    chain:rewrite()
    assert.stub(custom_policy_1.rewrite).was_called()

    chain:access()
    assert.stub(custom_policy_2.access).was_called()
  end)

  it('uses APIcast as default when no policies are specified', function()
    assert.equal(1, #_M)
    assert.equal('APIcast', _M[1]._NAME)
  end)

  it('calls the policies in the order specified when building the chain', function()
    -- Each policy inserts its name in a table so we know the order in which
    -- they were run.
    local execution_order = {}

    local policies = { policy.new('1'), policy.new('2'), policy.new('3') }
    for _, custom_policy in ipairs(policies) do
      custom_policy['init'] = function()
        table.insert(execution_order, custom_policy._NAME)
      end
    end

    local sorted_policies = { policies[2], policies[3], policies[1] }
    local chain = _M.build(sorted_policies)

    chain:init()
    assert.same({'2', '3', '1'}, execution_order)
  end)

  it('does not allow to modify phase methods after the chain has been built', function()
    for _, phase in policy.phases() do
      assert.has_error(function()
        _M[phase] = function() end
      end, 'readonly table')
    end
  end)

  it('does not allow to add new methods to the chain after it has been built', function()
    assert.has_error(function()
      _M['new_phase'] = function() end
    end, 'readonly table')
  end)

  describe('.insert', function()

    it('adds policy to the end of the chain', function()
      local chain = _M.new({ 'one', 'two' })

      chain:insert(policy)

      assert.equal(policy, chain[3])
      assert.equal(3, #chain)
    end)

    it('adds a policy to specific position', function()
      local chain = _M.new({ 'one', 'two'})

      chain:insert(policy, 2)
      assert.equal(policy, chain[2])
      assert.equal('one', chain[1])
      assert.equal('two', chain[3])
      assert.equal(3, #chain)
    end)

    it('errors when inserting to frozen chain', function()
      local chain = _M.new({}):freeze()

      local ok, err = chain:insert(policy, 1)

      assert.is_nil(ok)
      assert.equal(err, 'frozen')
      assert.equal(0, #chain)
    end)
  end)

  describe('.export', function()
    it('returns the data exposed by each of its policies', function()
      local policy_1 = policy.new('1')
      policy_1.export = function() return { shared_data_1 = '1' } end

      local policy_2 = policy.new('2')
      policy_2.export = function() return { shared_data_2 = '2' } end

      local chain = _M.build({ policy_1, policy_2 })

      local shared_data = chain:export()
      assert.equal('1', shared_data['shared_data_1'])
      assert.equal('2', shared_data['shared_data_2'])
    end)

    it('returns a read-only list', function()
      local policy_1 = policy.new('1')
      policy_1.export = function() return { shared_data = '1' } end

      local chain = _M.build({ policy_1 })

      local shared_data = chain:export()

      assert.has_error(function()
        shared_data.new_shared_data = 'some_data'
      end, 'readonly list')
      assert.is_nil(shared_data.new_shared_data)
    end)

    describe('when several policies expose the same data', function()
      it('returns the data exposed by the policy that comes first in the chain', function()
        local policy_1 = policy.new('custom_reporter')
        policy_1.export = function() return { shared_data_1 = '1' } end

        local policy_2 = policy.new('custom_authorizer')
        policy_2.export = function() return { shared_data_1 = '2' } end

        local chain = _M.build({ policy_1, policy_2 })

        local shared_data = chain:export()
        assert.equal('1', shared_data['shared_data_1'])
      end)
    end)
  end)

  describe('.default', function()
    it('returns a default policy chain', function()
      local default = _M.default()

      assert(#default > 1, 'has <= 1 policy')
    end)

    it('returns not frozen chain', function()
      assert.falsy(_M.default().frozen)
    end)
  end)
end)
