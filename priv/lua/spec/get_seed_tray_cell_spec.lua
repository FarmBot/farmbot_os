local get_seed_tray_cell = require("get_seed_tray_cell")

_G.toast = spy.new(function() end)
_G.send_message = spy.new(function() end)

describe("get_seed_tray_cell()", function()
  before_each(function()
    _G.toast:clear()
    _G.send_message:clear()
  end)

  it("gets cell", function()
    local tray = {
      pointer_type = "ToolSlot",
      pullout_direction = 1,
      x = 0,
      y = 0,
      z = 0,
    }
    local cell = get_seed_tray_cell(tray, "a1")

    assert.spy(toast).was_not_called()
    assert.spy(send_message).was_not_called()
    assert.are.same({ x = 1.25, y = -18.75, z = 0}, cell)
  end)

  it("gets a different cell", function()
    local tray = {
      pointer_type = "ToolSlot",
      pullout_direction = 1,
      x = 0,
      y = 0,
      z = 0,
    }
    local cell = get_seed_tray_cell(tray, "b1")

    assert.spy(toast).was_not_called()
    assert.spy(send_message).was_not_called()
    assert.are.same({ x = -11.25, y = -18.75, z = 0}, cell)
  end)

  it("handles different pullout direction", function()
    local tray = {
      pointer_type = "ToolSlot",
      pullout_direction = 2,
      x = 0,
      y = 0,
      z = 0,
    }
    local cell = get_seed_tray_cell(tray, "a1")

    assert.spy(toast).was_not_called()
    assert.spy(send_message).was_not_called()
    assert.are.same({ x = -36.25, y = 18.75, z = 0}, cell)
  end)

  it("handles wrong type", function()
    local tray = {
      pointer_type = "Plant",
      pullout_direction = 1,
      x = 0,
      y = 0,
      z = 0,
    }
    local cell = get_seed_tray_cell(tray, "a1")

    assert.spy(toast).was.called_with("Seed Tray variable must be a seed tray in a slot", "error")
    assert.spy(send_message).was_not_called()
    assert.is_falsy(cell)
  end)

  it("handles wrong cell id", function()
    local tray = {
      pointer_type = "ToolSlot",
      pullout_direction = 1,
      x = 0,
      y = 0,
      z = 0,
    }
    local cell = get_seed_tray_cell(tray, "x9")

    assert.spy(toast).was.called_with("Seed Tray Cell must be one of **A1** through **D4**", "error")
    assert.spy(send_message).was_not_called()
    assert.is_falsy(cell)
  end)

  it("handles wrong pullout direction", function()
    local tray = {
      pointer_type = "ToolSlot",
      pullout_direction = 3,
      x = 0,
      y = 0,
      z = 0,
    }
    local cell = get_seed_tray_cell(tray, "a1")

    assert.spy(toast).was_not_called()
    assert.spy(send_message).was.called_with("error", "Seed Tray **SLOT DIRECTION** must be `Positive X` or `Negative X`")
    assert.is_falsy(cell)
  end)
end)
