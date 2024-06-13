local verify_tool = require("verify_tool")

_G.toast = spy.new(function() end)
_G.send_message = spy.new(function() end)
_G.get_tool = spy.new(function() return { name = "My Tool" } end)

describe("verify_tool()", function()
  before_each(function()
    _G.toast:clear()
    _G.send_message:clear()
  end)

  it("handles missing tool detection", function()
    _G.get_device = spy.new(function() end)
    _G.read_pin = spy.new(function() return 1 end)

    local result = verify_tool()

    assert.spy(toast).was.called_with("No tool detected on the UTM - there is no electrical connection between UTM pins B and C.", "error")
    assert.spy(send_message).was_not_called()
    assert.is_falsy(result)
  end)

  it("handles missing mounted tool", function()
    _G.get_device = spy.new(function() end)
    _G.read_pin = spy.new(function() return 0 end)

    local result = verify_tool()

    assert.spy(toast).was.called_with("A tool is mounted but FarmBot does not know which one - check the **MOUNTED TOOL** dropdown in the Tools panel.", "error")
    assert.spy(send_message).was_not_called()
    assert.is_falsy(result)
  end)

  it("handles missing mounted tool", function()
    _G.get_device = spy.new(function() return 1 end)
    _G.read_pin = spy.new(function() return 0 end)

    local result = verify_tool()

    assert.spy(toast).was_not_called()
    assert.spy(send_message).was.called_with("success", "The My Tool is mounted on the UTM")
    assert.is_truthy(result)
  end)
end)
