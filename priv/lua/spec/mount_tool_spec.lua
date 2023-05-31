local mount_tool = require("mount_tool")

_G.toast = spy.new(function() end)
_G.set_job_progress = spy.new(function() end)
_G.safe_z = spy.new(function() end)
_G.move = spy.new(function() end)
_G.move_absolute = spy.new(function() end)
_G.update_device = spy.new(function() end)

describe("mount_tool()", function()
  before_each(function()
    _G.toast:clear()
    _G.set_job_progress:clear()
    _G.safe_z:clear()
    _G.move:clear()
    _G.move_absolute:clear()
    _G.update_device:clear()
  end)

  it("doesn't mount tool when tool is detected", function()
    _G.read_pin = spy.new(function() return 0 end)
    _G.get_device = spy.new(function() end)
    _G.api = spy.new(function() end)
    local slot = {
      pointer_type = "ToolSlot",
    }

    mount_tool(slot)

    assert.spy(api).was_not_called()
    assert.spy(toast).was.called_with("A tool is already mounted to the UTM - there is an electrical connection between UTM pins B and C.", "error")
  end)

  it("doesn't mount tool when tool is mounted", function()
    _G.read_pin = spy.new(function() return 1 end)
    _G.get_device = spy.new(function() return 1 end)
    _G.api = spy.new(function() end)
    local slot = {
      pointer_type = "ToolSlot",
    }

    mount_tool(slot)

    assert.spy(api).was_not_called()
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("There is already a tool mounted to the UTM - check the **MOUNTED TOOL** dropdown in the Tools panel.", "error")
  end)

  it("handles slot wrong type", function()
    _G.read_pin = spy.new(function() return 1 end)
    _G.get_device = spy.new(function() end)
    _G.api = spy.new(function() end)
    local slot = {
      pointer_type = "Plant",
    }

    mount_tool(slot)

    assert.spy(api).was_not_called()
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("Provided location must be a tool in a slot", "error")
  end)

  it("handles missing slot direction", function()
    _G.read_pin = spy.new(function() return 1 end)
    _G.get_device = spy.new(function() end)
    _G.api = spy.new(function() end)
    local slot = {
      pointer_type = "ToolSlot",
      pullout_direction = 0,
    }

    mount_tool(slot)

    assert.spy(api).was_not_called()
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("Tool slot must have a direction", "error")
  end)

  it("handles gantry mounted slots", function()
    _G.read_pin = spy.new(function() return 1 end)
    _G.get_device = spy.new(function() end)
    _G.api = spy.new(function() end)
    local slot = {
      pointer_type = "ToolSlot",
      pullout_direction = 1,
      gantry_mounted = true,
    }

    mount_tool(slot)

    assert.spy(api).was_not_called()
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("Tool slot cannot be gantry mounted", "error")
  end)

  it("handles missing tool", function()
    _G.read_pin = spy.new(function() return 1 end)
    _G.get_device = spy.new(function() end)
    _G.api = spy.new(function() end)
    local slot = {
      pointer_type = "ToolSlot",
      pullout_direction = 1,
      tool_id = 1,
    }

    mount_tool(slot)

    assert.spy(api).was.called(1)
    assert.spy(update_device).was_not_called()
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("API error", "error")
  end)

  it("fails", function()
    _G.read_pin = spy.new(function() return 1 end)
    _G.get_device = spy.new(function() end)
    _G.api = spy.new(function() return { name = "My Tool" } end)
    local slot = {
      pointer_type = "ToolSlot",
      pullout_direction = 1,
      tool_id = 1,
      x = 0,
      y = 0,
      z = 0,
    }

    mount_tool(slot)

    assert.spy(api).was.called(1)
    assert.spy(move).was.called(3)
    assert.spy(set_job_progress).was.called(5)
    assert.spy(move_absolute).was.called(1)
    assert.spy(safe_z).was.called(1)
    assert.spy(read_pin).was.called(2)
    assert.spy(update_device).was_not_called()
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with("Tool mounting failed - no electrical connection between UTM pins B and C.", "error")
  end)

  it("fetches tool slot", function()
    called_once = false
    _G.read_pin = spy.new(function()
      if not called_once then
        called_once = true
        return 1
      end
      return 0
    end)
    _G.get_device = spy.new(function() end)
    _G.api = spy.new(function(inputs)
      if string.match(inputs.url, "points") then
        return {
          point0 = {
              pointer_type = "ToolSlot",
              pullout_direction = 1,
              tool_id = 1,
              x = 0,
              y = 0,
              z = 0,
           },
        }
      end
      if string.match(inputs.url, "tools/1") then
        return {
          name = "My Tool",
        }
      end
      if string.match(inputs.url, "tools") then
        return {
          tool0 = { id = 1, name = "My Tool" },
        }
      end
    end)

    mount_tool("My Tool")

    assert.spy(api).was.called(3)
    assert.spy(toast).was.called(1)
    assert.spy(move).was.called(3)
    assert.spy(set_job_progress).was.called(5)
    assert.spy(move_absolute).was.called(1)
    assert.spy(safe_z).was.called(1)
    assert.spy(read_pin).was.called(2)
    assert.spy(update_device).was.called(1)
    assert.spy(toast).was.called_with("My Tool mounted", "success")
  end)

  it("doesn't fetch tool slot: tools api error", function()
    _G.api = spy.new(function() end)
    mount_tool("My Tool")
    assert.spy(toast).was.called_with("API error", "error")
  end)

  it("doesn't fetch tool slot: tool not found", function()
    _G.api = spy.new(function(inputs) return {} end)
    mount_tool("My Tool")
    assert.spy(toast).was.called_with("'My Tool' tool not found", "error")
  end)

  it("doesn't fetch tool slot: points api error", function()
    _G.api = spy.new(function(inputs)
      if string.match(inputs.url, "tools") then
        return {
          tool0 = { id = 1, name = "My Tool" },
        }
      end
    end)
    mount_tool("My Tool")
    assert.spy(toast).was.called_with("API error", "error")
  end)

  it("doesn't fetch tool slot: tool slot not found", function()
    _G.api = spy.new(function(inputs)
      if string.match(inputs.url, "points") then
        return {}
      end
      if string.match(inputs.url, "tools") then
        return {
          tool0 = { id = 1, name = "My Tool" },
        }
      end
    end)
    mount_tool("My Tool")
    assert.spy(toast).was.called_with("Tool slot not found", "error")
  end)

  for i = 1, 4 do
    it("mounts: slot_dir == " .. i, function()
      called_once = false
      _G.read_pin = spy.new(function()
        if not called_once then
          called_once = true
          return 1
        end
        return 0
      end)
      _G.get_device = spy.new(function() end)
      _G.api = spy.new(function() return { name = "My Tool" } end)
      local slot = {
        pointer_type = "ToolSlot",
        pullout_direction = i,
        tool_id = 1,
        x = 0,
        y = 0,
        z = 0,
      }

      mount_tool(slot)

      assert.spy(api).was.called(1)
      assert.spy(toast).was.called(1)
      assert.spy(move).was.called(3)
      assert.spy(set_job_progress).was.called(5)
      assert.spy(move_absolute).was.called(1)
      assert.spy(safe_z).was.called(1)
      assert.spy(read_pin).was.called(2)
      assert.spy(update_device).was.called(1)
      assert.spy(toast).was.called_with("My Tool mounted", "success")
    end)
  end
end)
