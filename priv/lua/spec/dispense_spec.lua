local dispense = require("dispense")

_G.toast = spy.new(function() end)
_G.send_message = spy.new(function() end)
_G.wait_with_progress = spy.new(function() end)
_G.on = spy.new(function() end)
_G.off = spy.new(function() end)
_G.os = { time = function() return 1000 end }

describe("dispense()", function()
  before_each(function()
    _G.toast:clear()
    _G.send_message:clear()
    _G.wait_with_progress:clear()
    _G.on:clear()
    _G.off:clear()
  end)

  it("handles missing tool list", function()
    _G.api = spy.new(function() end)
    dispense(100)

    assert.spy(api).was.called(1)
    assert.spy(toast).was.called_with("API error", "error")
    assert.spy(on).was_not_called()
  end)

  it("handles missing tool", function()
    _G.api = spy.new(function() return {} end)
    dispense(100)

    assert.spy(api).was.called(1)
    assert.spy(toast).was.called_with("You must have a tool named \"Watering Nozzle\" to use this sequence.", "error")
    assert.spy(on).was_not_called()
  end)

  it("accepts tool name", function()
    _G.api = spy.new(function() return {} end)
    dispense(100, { tool_name = "nozzle" })

    assert.spy(api).was.called(1)
    assert.spy(toast).was.called_with("You must have a tool named \"nozzle\" to use this sequence.", "error")
    assert.spy(on).was_not_called()
  end)

  it("handles missing flow rate", function()
    _G.api = spy.new(function()
      return {
        {
          name = "Watering Nozzle",
          flow_rate_ml_per_s = 0,
        }
      }
    end)
    dispense(100)

    assert.spy(api).was.called(1)
    assert.spy(toast).was.called_with("**FLOW RATE (mL/s)** must be greater than 0 for the Watering Nozzle tool.", "error")
    assert.spy(on).was_not_called()
  end)

  it("handles missing amount", function()
    _G.api = spy.new(function()
      return {
        {
          name = "Watering Nozzle",
          flow_rate_ml_per_s = 10,
        }
      }
    end)
    dispense(0)

    assert.spy(api).was.called(1)
    assert.spy(toast).was.called_with("Liquid volume was 0mL. Skipping.", "warn")
    assert.spy(on).was_not_called()
  end)

  it("handles excessive amount", function()
    _G.api = spy.new(function()
      return {
        {
          name = "Watering Nozzle",
          flow_rate_ml_per_s = 10,
        }
      }
    end)
    dispense(100000)

    assert.spy(api).was.called(1)
    assert.spy(toast).was.called_with("Liquid volume cannot be more than 10,000mL", "error")
    assert.spy(on).was_not_called()
  end)

  it("dispenses amount", function()
    _G.api = spy.new(function()
      return {
        {
          name = "Watering Nozzle",
          flow_rate_ml_per_s = 10,
        }
      }
    end)
    dispense(100)

    assert.spy(api).was.called(1)
    assert.spy(toast).was_not_called()
    assert.spy(send_message).was.called_with("info", "Dispensing 100mL over 10 seconds")
    assert.spy(on).was.called_with(8)
    assert.spy(wait_with_progress).was.called_with(10000, {
      job = "Dispensing 100mL",
      status = "Dispensing",
    })
    assert.spy(off).was.called_with(8)
  end)

  for _, test in pairs({
    { tool = "nozzle", rate = 1000, pin = 10, ml = 100, seconds = 0.1 },
    { tool = "hose", rate = 10, pin = 9, ml = 1000, seconds = 100 },
    { tool = "pipe", rate = 10, pin = 9, ml = 1111, seconds = 111.1 },
  }) do
    it("dispenses " .. test.ml .. "mL through " .. test.tool .. " at "
       .. test.rate .. "mL/s over " .. test.seconds .. " seconds", function()
      _G.api = spy.new(function()
        return {
          {
            name = test.tool,
            flow_rate_ml_per_s = test.rate,
          }
        }
      end)
      dispense(test.ml, { tool_name = test.tool, pin = test.pin })

      local job_message = "Dispensing " .. test.ml .. "mL"
      assert.spy(api).was.called(1)
      assert.spy(toast).was_not_called()
      assert.spy(send_message).was.called_with("info",
        "Dispensing " .. test.ml .. "mL over " .. test.seconds .. " seconds")
      assert.spy(on).was.called_with(test.pin)
      assert.spy(wait_with_progress).was.called_with(test.seconds * 1000, {
        job = job_message,
        status = "Dispensing",
      })
      assert.spy(off).was.called_with(test.pin)
    end)
  end
end)
