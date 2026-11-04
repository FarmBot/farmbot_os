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

describe("move() offsets", function()
  it("adds offsets without overwriting current coordinates", function()
    local request
    _G.cs_eval = function(value) request = value end

    move({ offset = { x = 10, y = -20, z = 0 } })

    assert.same({
      axis_addition("x", 10),
      axis_addition("y", -20),
      axis_addition("z", 0),
    }, request.body[1].body)
  end)

  it("applies offsets after absolute coordinates", function()
    local request
    _G.cs_eval = function(value) request = value end

    move({ x = 0, offset = { x = -5 } })

    assert.same({
      axis_overwrite("x", 0),
      axis_addition("x", -5),
    }, request.body[1].body)
  end)
end)

describe("move() variance", function()
  local request

  before_each(function()
    request = nil
    _G.cs_eval = function(value) request = value end
  end)

  it("adds random operands for each supplied axis, including zero", function()
    move({ variance = { x = 10, y = 5, z = 0 } })

    local expected = {}
    for index, axis in ipairs({"x", "y", "z"}) do
      expected[index] = {
        kind = "axis_addition",
        args = {
          axis = axis,
          axis_operand = { kind = "random", args = { variance = ({10, 5, 0})[index] } },
        },
      }
    end
    assert.same(expected, request.body[1].body)
  end)

  it("omits axes without variance", function()
    move({ variance = { y = 5 } })

    assert.same({{
      kind = "axis_addition",
      args = {
        axis = "y",
        axis_operand = { kind = "random", args = { variance = 5 } },
      },
    }}, request.body[1].body)
  end)

  it("applies variance after coordinates and offsets, before movement settings", function()
    local input = {
      x = 100, offset = { x = 5 }, variance = { x = 10 },
      speed = 50, grouping = "xy,z", route = "high", safe_z = true,
    }

    move(input)

    assert.same({
      axis_overwrite("x", 100),
      axis_addition("x", 5),
      {
        kind = "axis_addition",
        args = {
          axis = "x",
          axis_operand = { kind = "random", args = { variance = 10 } },
        },
      },
      speed_overwrite("x", 50),
      speed_overwrite("y", 50),
      speed_overwrite("z", 50),
      axis_order(input),
      { kind = "safe_z", args = {} },
    }, request.body[1].body)
    assert.same({
      x = 100, offset = { x = 5 }, variance = { x = 10 },
      speed = 50, grouping = "xy,z", route = "high", safe_z = true,
    }, input)
  end)
end)
