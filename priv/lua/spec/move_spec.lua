local move = require("move")

_G.cs_eval = spy.new(function() end)

describe("move()", function()
  before_each(function()
    _G.cs_eval:clear()
  end)

  it("moves with empty args", function()
    move({})

    assert.spy(cs_eval).was.called()
    assert.spy(cs_eval).was.called_with({
      kind = "rpc_request",
      args = { label = "move_cmd_lua", priority = 500 },
      body = { {
        kind = "move",
        args = {},
        body = {},
      } }
    })
  end)

  it("moves with args", function()
    move({ x = 1, speed = 100, safe_z = true, grouping = "xyz", route = "in_order" })

    assert.spy(cs_eval).was.called()
    assert.spy(cs_eval).was.called_with({
      kind = "rpc_request",
      args = { label = "move_cmd_lua", priority = 500 },
      body = {{
        kind = "move",
        args = {},
        body = {
          [1] = {
            kind = "axis_overwrite",
            args = {
              axis = "x",
              axis_operand = { kind = "numeric", args = { number = 1 } }
            }
          },
          [2] = {
            kind = "speed_overwrite",
            args = {
              axis = "x",
              speed_setting = { kind = "numeric", args = { number = 100 } }
            }
          },
          [3] = {
            kind = "speed_overwrite",
            args = {
              axis = "y",
              speed_setting = { kind = "numeric", args = { number = 100 } }
            }
          },
          [4] = {
            kind = "speed_overwrite",
            args = {
              axis = "z",
              speed_setting = { kind = "numeric", args = { number = 100 } }
            }
          },
          [5] = { kind = "axis_order", args = { grouping = "xyz", route = "in_order" } },
          [6] = { kind = "safe_z", args = {} },
        },
      }}
    })
  end)

  it("omits safe_z when disabled", function()
    move({ safe_z = false })

    assert.spy(cs_eval).was.called()
    assert.spy(cs_eval).was.called_with({
      kind = "rpc_request",
      args = { label = "move_cmd_lua", priority = 500 },
      body = {{
        kind = "move",
        args = {},
        body = {},
      }}
    })
  end)
end)
