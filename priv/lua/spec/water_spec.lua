local water = require("water")

_G.dispense = spy.new(function() end)
_G.get_curve = spy.new(function()
  return { day = function() return 100 end }
end)
_G.toast = spy.new(function() end)
_G.send_message = spy.new(function() end)

describe("water()", function()
  before_each(function()
    _G.toast:clear()
    _G.send_message:clear()
    _G.dispense:clear()
  end)

  it("gets water amount and calls dispense()", function()
    local plant = {
      name = "Plant",
      age = 10,
      water_curve_id = 1,
      x = 1,
      y = 2,
      z = 3,
    }
    water(plant)

    assert.spy(get_curve).was.called_with(1)
    assert.spy(dispense).was.called_with(100, nil)
    assert.spy(send_message).was.called_with("info", "Watering 10 day old Plant at (1, 2, 3) 100mL")
    assert.spy(toast).was_not_called()
  end)

  it("passes params", function()
    local plant = {
      name = "Plant",
      age = 10,
      water_curve_id = 1,
      x = 1,
      y = 2,
      z = 3,
    }
    water(plant, { tool_name = "tool", pin = 10 })

    assert.spy(get_curve).was.called_with(1)
    assert.spy(dispense).was.called_with(100, { tool_name = "tool", pin = 10})
  end)

  it("handles missing watering curve", function()
    local plant = {
      name = "Plant",
      age = 10,
      water_curve_id = nil,
      x = 1,
      y = 2,
      z = 3,
    }
    water(plant)

    assert.spy(get_curve).was.called_with(1)
    assert.spy(dispense).was_not_called()
    assert.spy(toast).was.called_with("Plant at (1, 2, 3) has no assigned water curve. Skipping.", "warn")
    assert.spy(send_message).was_not_called()
  end)
end)
