local rpc = require("rpc")

_G.cs_eval = spy.new(function() end)
local math = require("math")
math.random = spy.new(function() return "0.123" end)

describe("rpc()", function()
  it("generates rpc request and calls cs_eval()", function()
    rpc({ kind = "sync", args = {}})

    assert.spy(cs_eval).was.called()
    assert.spy(cs_eval).was.called_with({
      kind = "rpc_request",
      args = { label = "0.1230.123" },
      body = { { kind = "sync", args = {}} }
    })
  end)
end)
