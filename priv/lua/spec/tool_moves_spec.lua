local move = require("move")
local move_with_tool = require("move_with_tool")
local resolve_tool_move = require("resolve_tool_move")

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
    _G.resolve_tool_move = spy.new(resolve_tool_move)
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
      local stage_coordinates = {
        [0] = {103, 203, 303},
        [1] = {93, 203, 303},
        [2] = {93, 183, 303},
        [3] = {93, 183, 273},
      }
      local coordinates = stage_coordinates[stage]
      for index, axis in ipairs({"x", "y", "z"}) do
        expected[#expected + 1] = axis_overwrite(axis, coordinates[index])
      end
      for _, axis in ipairs({"x", "y", "z"}) do
        expected[#expected + 1] = speed_overwrite(axis, 50)
      end
      expected[#expected + 1] = axis_order(input)
      expected[#expected + 1] = { kind = "safe_z", args = {} }

      move_with_tool(input)

      assert.same(expected, request.body[1].body)
      assert.same(original, input)
      local forwarded = _G.move.calls[1].vals[1]
      assert.equals(coordinates[1], forwarded.x)
      assert.equals(coordinates[2], forwarded.y)
      assert.equals(coordinates[3], forwarded.z)
      assert.is_nil(forwarded.name)
      assert.is_nil(forwarded.offset)
      assert.spy(_G.resolve_tool_move).was.called_with(input)
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
      axis_overwrite("x", 5),
      axis_overwrite("y", 398),
      axis_overwrite("z", -243),
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
      axis_overwrite("x", 103),
      axis_overwrite("y", 203),
      axis_overwrite("z", 303),
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
    local expected = {
      axis_overwrite("x", 0),
    }

    move_with_tool(input)

    assert.same(expected, request.body[1].body)
  end)

  it("applies tool offsets only to axes with coordinates", function()
    slot.mount_stage = 3
    input = { name = "Seeder", x = 0 }

    move_with_tool(input)

    assert.same({
      axis_overwrite("x", -11),
    }, request.body[1].body)
  end)

  it("preserves explicit offsets on axes without coordinates", function()
    slot.mount_stage = 3
    input = { name = "Seeder", x = 100, offset = { y = 5, z = 0 } }

    move_with_tool(input)

    assert.same({
      axis_overwrite("x", 89),
      axis_addition("y", 5),
      axis_addition("z", 0),
    }, request.body[1].body)
    assert.same({ name = "Seeder", x = 100, offset = { y = 5, z = 0 } }, input)
  end)

  it("preserves offset-only moves without applying tool offsets", function()
    slot.mount_stage = 3
    input = { name = "Seeder", offset = { x = 4, y = 5, z = 6 } }

    move_with_tool(input)

    assert.same({
      axis_addition("x", 4),
      axis_addition("y", 5),
      axis_addition("z", 6),
    }, request.body[1].body)
  end)
end)

describe("resolve_tool_move()", function()
  before_each(function()
    _G.get_tool = spy.new(function()
      return { effector_offset_x = 1, effector_offset_y = 2, effector_offset_z = 3 }
    end)
    _G.get_slot_for_tool = spy.new(function()
      return { mount_stage = 3, mount_offset_x = 10, mount_offset_y = 20, mount_offset_z = 30 }
    end)
    _G.move = spy.new(function() end)
  end)

  it("returns resolved coordinates and movement settings without changing input", function()
    local input = {
      id = 1, name = "Seeder", type = "seeder", x = 100, y = 200, z = 300,
      offset = { x = 4, y = 5, z = 6 },
      speed = 50, grouping = "xy,z", route = "in_order", safe_z = true,
    }

    local result = resolve_tool_move(input)

    assert.same({
      x = 93, y = 183, z = 273,
      speed = 50, grouping = "xy,z", route = "in_order", safe_z = true,
    }, result)
    assert.same({
      id = 1, name = "Seeder", type = "seeder", x = 100, y = 200, z = 300,
      offset = { x = 4, y = 5, z = 6 },
      speed = 50, grouping = "xy,z", route = "in_order", safe_z = true,
    }, input)
    assert.spy(get_tool).was.called_with({ id = 1, name = "Seeder", type = "seeder" })
    assert.spy(get_slot_for_tool).was.called_with({ id = 1, name = "Seeder", type = "seeder" })
    assert.spy(_G.move).was_not_called()
  end)

  it("copies offsets only for axes without coordinates", function()
    local input = { name = "Seeder", x = 0, offset = { x = 4, y = 5, z = 0 } }

    local result = resolve_tool_move(input)

    assert.same({ x = -7, offset = { y = 5, z = 0 } }, result)
    result.offset.y = 99
    assert.same({ name = "Seeder", x = 0, offset = { x = 4, y = 5, z = 0 } }, input)
    assert.spy(_G.move).was_not_called()
  end)

  it("omits coordinates and offsets when no movement is requested", function()
    assert.same({}, resolve_tool_move({ id = 1, offset = {} }))
    assert.spy(_G.move).was_not_called()
  end)
end)
