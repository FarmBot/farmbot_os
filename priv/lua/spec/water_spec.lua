local water = require("water")

_G.os.time = spy.new(function() return 100 end)
_G.to_unix = spy.new(function() return 100 - 10 * 86400 end)
_G.dispense = spy.new(function() end)
_G.get_curve = spy.new(function()
  return { day = function() return 100 end }
end)
_G.toast = spy.new(function() end)
_G.send_message = spy.new(function() end)
_G.move = spy.new(function() end)
_G.safe_z = spy.new(function() return 0 end)
_G.set_job = spy.new(function() end)
_G.complete_job = spy.new(function() end)

describe("water()", function()
  before_each(function()
    _G.toast:clear()
    _G.get_curve:clear()
    _G.send_message:clear()
    _G.dispense:clear()
    _G.move:clear()
    _G.set_job:clear()
    _G.complete_job:clear()
  end)

  it("gets water amount from age and calls dispense()", function()
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
    assert.spy(toast).was_not_called()
    assert.spy(set_job).was.called_with("Watering Plant at (1, 2)", { status = "Moving" })
    assert.spy(move).was.called_with({x = 1, y = 2, z = 0})
    assert.spy(set_job).was.called_with("Watering Plant at (1, 2)", { status = "Watering", percent = 50 })
    assert.spy(send_message).was.called_with("info", "Watering 10 day old Plant at (1, 2) 100mL")
    assert.spy(dispense).was.called_with(100, nil)
    assert.spy(complete_job).was.called_with("Watering Plant at (1, 2)")
  end)

  it("gets water amount from planted_at and calls dispense()", function()
    local plant = {
      name = "Plant",
      planted_at = "2021-03-31T19:42:18.173Z",
      water_curve_id = 1,
      x = 1,
      y = 2,
      z = 3,
    }
    water(plant)

    assert.spy(get_curve).was.called_with(1)
    assert.spy(toast).was_not_called()
    assert.spy(set_job).was.called_with("Watering Plant at (1, 2)", { status = "Moving" })
    assert.spy(move).was.called_with({x = 1, y = 2, z = 0})
    assert.spy(set_job).was.called_with("Watering Plant at (1, 2)", { status = "Watering", percent = 50 })
    assert.spy(send_message).was.called_with("info", "Watering 10 day old Plant at (1, 2) 100mL")
    assert.spy(dispense).was.called_with(100, nil)
    assert.spy(complete_job).was.called_with("Watering Plant at (1, 2)")
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
    assert.spy(dispense).was.called_with(100, { tool_name = "tool", pin = 10 })
  end)

  it("handles missing plant age", function()
    local plant = {
      name = "Plant",
      age = nil,
      water_curve_id = nil,
      x = 1,
      y = 2,
      z = 3,
    }
    water(plant)

    assert.spy(get_curve).was_not_called()
    assert.spy(toast).was.called_with("Plant at (1, 2) has not been planted yet. Skipping.", "warn")
    assert.spy(set_job).was_not_called()
    assert.spy(move).was_not_called()
    assert.spy(send_message).was_not_called()
    assert.spy(dispense).was_not_called()
    assert.spy(complete_job).was_not_called()
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

    assert.spy(get_curve).was_not_called()
    assert.spy(toast).was.called_with("Plant at (1, 2) has no assigned water curve. Skipping.", "warn")
    assert.spy(set_job).was_not_called()
    assert.spy(move).was_not_called()
    assert.spy(send_message).was_not_called()
    assert.spy(dispense).was_not_called()
    assert.spy(complete_job).was_not_called()
  end)
end)
