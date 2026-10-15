local move = require("move")
local move_with_tool = require("move_with_tool")

describe("move_with_tool()", function()
  local slot, tool, input, request

  before_each(function()
    slot = {
      x = 400, y = 500, z = 600,
      mount_offset_x = 10, mount_offset_y = 20, mount_offset_z = 30,
    }
    tool = { effector_offset_x = 1, effector_offset_y = 2, effector_offset_z = 3 }
    input = {
      name = "Seeder", x = 100, y = 200, z = 300,
      offset = { x = 4, y = 5, z = 6 },
      speed = 50, grouping = "xy,z", route = "in_order", safe_z = true,
    }
    _G.get_tool = spy.new(function() return tool end)
    _G.get_slot_for_tool = spy.new(function() return slot end)
    _G.move = spy.new(move)
    _G.cs_eval = spy.new(function(value) request = value end)
  end)

  for stage = 0, 3 do
    it("applies tool offsets at stage " .. stage, function()
      slot.mount_stage = stage
      local original = {
        name = "Seeder", x = 100, y = 200, z = 300,
        offset = { x = 4, y = 5, z = 6 },
        speed = 50, grouping = "xy,z", route = "in_order", safe_z = true,
      }
      local expected = {}
      for _, axis in ipairs({"x", "y", "z"}) do
        expected[#expected + 1] = axis_overwrite(axis, input[axis])
      end
      local stage_offsets = {
        [0] = {3, 3, 3},
        [1] = {-7, 3, 3},
        [2] = {-7, -17, 3},
        [3] = {-7, -17, -27},
      }
      local offsets = stage_offsets[stage]
      expected[#expected + 1] = axis_addition("x", offsets[1])
      expected[#expected + 1] = axis_addition("y", offsets[2])
      expected[#expected + 1] = axis_addition("z", offsets[3])
      for _, axis in ipairs({"x", "y", "z"}) do
        expected[#expected + 1] = speed_overwrite(axis, 50)
      end
      expected[#expected + 1] = axis_order(input)
      expected[#expected + 1] = { kind = "safe_z", args = {} }

      move_with_tool(input)

      assert.same(expected, request.body[1].body)
      assert.same(original, input)
      local forwarded = _G.move.calls[1].vals[1]
      assert.equals(input.x, forwarded.x)
      assert.equals(input.y, forwarded.y)
      assert.equals(input.z, forwarded.z)
      assert.spy(_G.move).was.called(1)
      assert.spy(_G.cs_eval).was.called(1)
      assert.spy(get_tool).was.called_with({name = "Seeder"})
      assert.spy(get_slot_for_tool).was.called_with({name = "Seeder"})
    end)
  end

  it("looks up a tool by type without movement fields", function()
    input = { type = "seeder", x = 6, y = 400, z = -240 }
    _G.get_tool = spy.new(function(selector)
      assert.same({type = "seeder"}, selector)
      return tool
    end)
    _G.get_slot_for_tool = spy.new(function(selector)
      assert.same({type = "seeder"}, selector)
      return slot
    end)

    move_with_tool(input)

    assert.spy(get_tool).was.called(1)
    assert.spy(get_slot_for_tool).was.called(1)
    assert.same({type = "seeder", x = 6, y = 400, z = -240}, input)
    assert.same({
      axis_overwrite("x", 6),
      axis_overwrite("y", 400),
      axis_overwrite("z", -240),
      axis_addition("x", -1),
      axis_addition("y", -2),
      axis_addition("z", -3),
    }, request.body[1].body)
  end)

  it("reports a missing tool without moving", function()
    tool = nil

    assert.has_error(function() move_with_tool(input) end, "Tool not found")

    assert.spy(get_slot_for_tool).was_not_called()
    assert.spy(_G.move).was_not_called()
    assert.spy(_G.cs_eval).was_not_called()
  end)

  it("handles a missing slot", function()
    slot = nil

    move_with_tool(input)

    assert.same({
      axis_overwrite("x", 100),
      axis_overwrite("y", 200),
      axis_overwrite("z", 300),
      axis_addition("x", 3),
      axis_addition("y", 3),
      axis_addition("z", 3),
      speed_overwrite("x", 50),
      speed_overwrite("y", 50),
      speed_overwrite("z", 50),
      axis_order(input),
      { kind = "safe_z", args = {} },
    }, request.body[1].body)
    assert.spy(_G.move).was.called(1)
  end)

  it("defaults missing stage and offsets to zero", function()
    tool = {}
    slot = { x = 400, y = 500, z = 600 }
    input = { name = "Seeder", x = 0 }
    local expected = { axis_overwrite("x", 0) }
    for _, axis in ipairs({"x", "y", "z"}) do
      expected[#expected + 1] = axis_addition(axis, 0)
    end

    move_with_tool(input)

    assert.same(expected, request.body[1].body)
  end)
end)
