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
    move({ x = 1, speed = 100, safe_z = true })

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
          [4] = {
            kind = "speed_overwrite",
            args = {
              axis = "x",
              speed_setting = { kind = "numeric", args = { number = 100 } }
            }
          },
          [5] = {
            kind = "speed_overwrite",
            args = {
              axis = "y",
              speed_setting = { kind = "numeric", args = { number = 100 } }
            }
          },
          [6] = {
            kind = "speed_overwrite",
            args = {
              axis = "z",
              speed_setting = { kind = "numeric", args = { number = 100 } }
            }
          },
          [7] = { kind = "safe_z", args = {} },
        },
      }}
    })
  end)
end)
