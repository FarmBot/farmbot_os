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
    _G.get_tool = spy.new(function() return {} end)
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

    assert.spy(get_tool).was.called_with({ type = "watering_nozzle" })
    assert.spy(get_curve).was.called_with(1)
    assert.spy(toast).was_not_called()
    assert.spy(set_job).was.called_with("Watering Plant", { status = "Moving" })
    assert.spy(move).was.called_with({x = 1, y = 2, z = 0})
    assert.spy(set_job).was.called_with("Watering Plant", { status = "Watering", percent = 50 })
    assert.spy(send_message).was.called_with("info", "Watering 10 day old Plant 100mL")
    assert.spy(dispense).was.called_with(100, nil)
    assert.spy(complete_job).was.called_with("Watering Plant")
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

    assert.spy(get_tool).was.called_with({ type = "watering_nozzle" })
    assert.spy(get_curve).was.called_with(1)
    assert.spy(toast).was_not_called()
    assert.spy(set_job).was.called_with("Watering Plant", { status = "Moving" })
    assert.spy(move).was.called_with({x = 1, y = 2, z = 0})
    assert.spy(set_job).was.called_with("Watering Plant", { status = "Watering", percent = 50 })
    assert.spy(send_message).was.called_with("info", "Watering 10 day old Plant 100mL")
    assert.spy(dispense).was.called_with(100, nil)
    assert.spy(complete_job).was.called_with("Watering Plant")
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
    assert.spy(get_tool).was.called_with({ name = "tool" })
    assert.spy(dispense).was.called_with(100, { tool_name = "tool", pin = 10 })
  end)

  for _, test in ipairs({
    { params = {}, offset_x = 5, offset_y = -3 },
    { params = { tool_name = "tool" }, offset_x = -5, offset_y = 3 },
  }) do
    it("applies nozzle offsets " .. test.offset_x .. ", " .. test.offset_y, function()
      _G.get_tool = spy.new(function()
        return { effector_offset_x = test.offset_x, effector_offset_y = test.offset_y }
      end)
      local plant = { name = "Plant", age = 10, water_curve_id = 1, x = 1, y = 2 }
      water(plant, test.params)

      assert.spy(move).was.called_with({
        x = 1 - test.offset_x,
        y = 2 - test.offset_y,
        z = 0,
      })
      assert.spy(toast).was_not_called()
      assert.spy(dispense).was.called_with(100, test.params)
      assert.spy(complete_job).was.called_with("Watering Plant")
    end)
  end

  for _, test in ipairs({
    { params = {}, query = { type = "watering_nozzle" }, message = "Watering nozzle not found" },
    { params = { tool_name = "tool" }, query = { name = "tool" }, message = 'Tool "tool" not found' },
  }) do
    it("stops when " .. test.message, function()
      _G.get_tool = spy.new(function() end)
      local plant = { name = "Plant", age = 10, water_curve_id = 1, x = 1, y = 2 }
      water(plant, test.params)

      assert.spy(get_tool).was.called_with(test.query)
      assert.spy(toast).was.called_with(test.message, "warn")
      assert.spy(set_job).was_not_called()
      assert.spy(move).was_not_called()
      assert.spy(send_message).was_not_called()
      assert.spy(dispense).was_not_called()
      assert.spy(complete_job).was_not_called()
    end)
  end

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
