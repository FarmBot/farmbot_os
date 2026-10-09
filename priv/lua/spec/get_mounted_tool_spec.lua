local get_mounted_tool = require("get_mounted_tool")

describe("get_mounted_tool()", function()
  before_each(function()
    _G.get_device = spy.new(function() end)
    _G.get_tool = spy.new(function() end)
  end)

  it("returns the mounted tool", function()
    local tool = {id = 123, name = "Seeder", type = "seeder"}
    _G.get_device = spy.new(function() return tool.id end)
    _G.get_tool = spy.new(function() return tool end)

    assert.are_equal(tool, get_mounted_tool())
    assert.spy(get_device).was.called_with("mounted_tool_id")
    assert.spy(get_tool).was.called_with({id = 123})
  end)

  it("returns nil without looking up a tool when none is mounted", function()
    assert.is_nil(get_mounted_tool())
    assert.spy(get_device).was.called_with("mounted_tool_id")
    assert.spy(get_tool).was_not_called()
  end)

  it("returns nil when the mounted tool is missing", function()
    _G.get_device = spy.new(function() return 123 end)

    assert.is_nil(get_mounted_tool())
    assert.spy(get_tool).was.called_with({id = 123})
  end)
end)
