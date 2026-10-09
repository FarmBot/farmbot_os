local verify_tool = require("verify_tool")

describe("verify_tool()", function()
  before_each(function()
    _G.toast = spy.new(function() end)
    _G.send_message = spy.new(function() end)
    _G.get_device = spy.new(function() return 1 end)
    _G.read_pin = spy.new(function() return 0 end)
    _G.get_tool = spy.new(function(params)
      if params.id == 1 then
        return {id = 1, name = "My Tool", type = "seeder"}
      elseif params.id == 2 then
        return {id = 2, name = "Other Tool", type = "water"}
      end
    end)
  end)

  local function assert_success(params)
    assert.is_true(verify_tool(params))
    assert.spy(toast).was_not_called()
    assert.spy(send_message).was.called_with("success", "The My Tool is mounted on the UTM")
  end

  local function assert_failure(params, message)
    assert.is_false(verify_tool(params))
    assert.spy(toast).was.called_with(message, "error")
    assert.spy(send_message).was_not_called()
  end

  it("handles missing tool detection", function()
    _G.read_pin = spy.new(function() return 1 end)

    assert_failure({name = "My Tool"}, "No tool detected on the UTM - there is no electrical connection between UTM pins B and C.")
    assert.spy(read_pin).was.called_with(63)
    assert.spy(get_tool).was_not_called()
  end)

  it("handles missing mounted tool ID", function()
    _G.get_device = spy.new(function() end)

    assert_failure({id = 1}, "A tool is mounted but FarmBot does not know which one - check the **MOUNTED TOOL** dropdown in the Tools panel.")
    assert.spy(get_tool).was_not_called()
  end)

  it("verifies a tool without filters", function()
    assert_success()
    assert.spy(get_device).was.called_with("mounted_tool_id")
    assert.spy(get_tool).was.called_with({id = 1})
  end)

  it("verifies a tool with an empty filter table", function()
    assert_success({})
  end)

  it("verifies a matching name", function()
    assert_success({name = "My Tool"})
  end)

  it("rejects a mismatching name", function()
    assert_failure({name = "Other Tool"}, "Expected the Other Tool to be mounted, but the My Tool is.")
  end)

  it("verifies a matching type", function()
    assert_success({type = "seeder"})
  end)

  it("rejects a mismatching type", function()
    assert_failure({type = "water"}, "Expected a water tool to be mounted, but a seeder tool is.")
  end)

  it("verifies a matching ID", function()
    assert_success({id = 1})
  end)

  it("rejects a mismatching ID", function()
    assert_failure({id = 2}, "Expected the Other Tool to be mounted, but the My Tool tool is.")
    assert.spy(get_tool).was.called_with({id = 2})
  end)

  it("verifies when all filters match", function()
    assert_success({name = "My Tool", type = "seeder", id = 1})
  end)

  it("rejects a mismatching type even when the name and ID match", function()
    assert_failure({name = "My Tool", type = "water", id = 1}, "Expected a water tool to be mounted, but a seeder tool is.")
  end)

  it("rejects a mismatching ID even when the name and type match", function()
    assert_failure({name = "My Tool", type = "seeder", id = 2}, "Expected the Other Tool to be mounted, but the My Tool tool is.")
  end)

  it("handles a missing mounted tool record", function()
    _G.get_tool = spy.new(function() end)

    assert_failure({}, "Mounted tool not found - check the **MOUNTED TOOL** dropdown in the Tools panel.")
  end)

  it("handles a missing expected tool record", function()
    assert_failure({id = 999}, "Expected tool not found - check the provided tool ID.")
    assert.spy(get_tool).was.called_with({id = 999})
  end)
end)
