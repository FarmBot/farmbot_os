local sequence = require("sequence")

_G.rpc = spy.new(function() end)

describe("sequence()", function()
  before_each(function()
    _G.rpc:clear()
  end)

  it("generates rpc request and calls cs_eval()", function()
    sequence(1, { label = "value"})

    assert.spy(rpc).was.called()
    assert.spy(rpc).was.called_with({
      kind = "execute",
      args = { sequence_id = 1},
      body = { {
        kind = "parameter_application",
        args = { label = "label", data_value = "value" },
      } },
    })
  end)

  it("handles empty params", function()
    sequence(1)

    assert.spy(rpc).was.called()
    assert.spy(rpc).was.called_with({
      kind = "execute",
      args = { sequence_id = 1},
    })
  end)
end)
