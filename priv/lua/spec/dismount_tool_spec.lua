local dismount_tool = require("dismount_tool")

_G.get_device = spy.new(function() return 1 end)
_G.toast = spy.new(function() end)
_G.set_job_progress = spy.new(function() end)
_G.safe_z = spy.new(function() end)
_G.move = spy.new(function() end)
_G.move_absolute = spy.new(function() end)
_G.update_device = spy.new(function() end)
_G.get_tool = spy.new(function() end)

describe("dismount_tool()", function()
  before_each(function()
    _G.get_device:clear()
    _G.toast:clear()
    _G.set_job_progress:clear()
    _G.safe_z:clear()
    _G.move:clear()
    _G.move_absolute:clear()
    _G.update_device:clear()
  end)

  it("doesn't dismount tool when mounted_tool_id is nil", function()
    _G.get_device = spy.new(function() end)
    _G.api = spy.new(function() end)

    dismount_tool()

    assert.spy(api).was_not_called()
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("No tool is mounted to the UTM", "error")
  end)

  it("doesn't dismount tool when no tool is mounted", function()
    _G.get_device = spy.new(function() return 1 end)
    _G.verify_tool = spy.new(function() end)
    _G.api = spy.new(function() end)

    dismount_tool()

    assert.spy(api).was_not_called()
    assert.spy(toast).was_not_called()
  end)

  it("handles API error: points", function()
    _G.get_device = spy.new(function() return 1 end)
    _G.verify_tool = spy.new(function() return true end)
    _G.api = spy.new(function() end)

    dismount_tool()

    assert.spy(api).was.called(1)
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("API error", "error")
  end)

  it("handles missing slot", function()
    _G.get_device = spy.new(function() return 1 end)
    _G.verify_tool = spy.new(function() return true end)
    _G.api = spy.new(function(inputs)
      if string.match(inputs.url, "points") then
        return {
          point1 = { tool_id = 0 },
        }
      end
    end)
    _G.get_tool = spy.new(function() return { name = "My Tool" } end)

    dismount_tool()

    assert.spy(api).was.called(1)
    assert.spy(get_tool).was.called(1)
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("No slot found for the currently mounted tool (My Tool) - check the Tools panel", "error")
  end)

  it("handles missing slot direction", function()
    _G.get_device = spy.new(function() return 1 end)
    _G.verify_tool = spy.new(function() return true end)
    _G.api = spy.new(function(inputs)
      if string.match(inputs.url, "points") then
        return {
          point0 = { tool_id = 1, pullout_direction = 0 },
        }
      end
    end)
    _G.get_tool = spy.new(function() return { name = "My Tool" } end)

    dismount_tool()

    assert.spy(api).was.called(1)
    assert.spy(get_tool).was.called(1)
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("Tool slot must have a direction", "error")
  end)

  it("handles gantry mounted slots", function()
    _G.get_device = spy.new(function() return 1 end)
    _G.verify_tool = spy.new(function() return true end)
    _G.api = spy.new(function(inputs)
      if string.match(inputs.url, "points") then
        return {
          point0 = { tool_id = 1, pullout_direction = 1, gantry_mounted = true },
        }
      end
    end)
    _G.get_tool = spy.new(function() return { name = "My Tool" } end)

    dismount_tool()

    assert.spy(api).was.called(1)
    assert.spy(get_tool).was.called(1)
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("Tool slot cannot be gantry mounted", "error")
  end)

  it("fails", function()
    _G.get_device = spy.new(function() return 1 end)
    _G.verify_tool = spy.new(function() return true end)
    _G.api = spy.new(function(inputs)
      if string.match(inputs.url, "points") then
        return {
          point0 = { tool_id = 1, pullout_direction = 1, x = 0, y = 0, z = 0 },
        }
      end
    end)
    _G.get_tool = spy.new(function() return { name = "My Tool" } end)
    _G.read_pin = spy.new(function() return 0 end)

    dismount_tool()

    assert.spy(api).was.called(1)
    assert.spy(get_tool).was.called(1)
    assert.spy(move).was.called(4)
    assert.spy(set_job_progress).was.called(6)
    assert.spy(move_absolute).was.called(1)
    assert.spy(safe_z).was.called(1)
    assert.spy(read_pin).was.called(1)
    assert.spy(update_device).was_not_called()
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("Tool dismounting failed - there is still an electrical connection between UTM pins B and C.", "error")
  end)

  for i = 1, 4 do
    it("dismounts: slot_dir == " .. i, function()
      _G.get_device = spy.new(function() return 1 end)
      _G.verify_tool = spy.new(function() return true end)
      _G.api = spy.new(function(inputs)
        if string.match(inputs.url, "points") then
          return {
            point0 = { tool_id = 1, pullout_direction = i, x = 0, y = 0, z = 0 },
          }
        end
      end)
      _G.get_tool = spy.new(function() return { name = "My Tool" } end)
      _G.read_pin = spy.new(function() return 1 end)

      dismount_tool()

      assert.spy(api).was.called(1)
      assert.spy(get_tool).was.called(1)
      assert.spy(toast).was.called(1)
      assert.spy(move).was.called(4)
      assert.spy(set_job_progress).was.called(6)
      assert.spy(move_absolute).was.called(1)
      assert.spy(safe_z).was.called(1)
      assert.spy(read_pin).was.called(1)
      assert.spy(update_device).was.called(1)
      assert.spy(toast).was.called_with("My Tool dismounted", "success")
    end)
  end
end)
