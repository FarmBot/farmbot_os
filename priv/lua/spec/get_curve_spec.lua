local get_curve = require("get_curve")

_G.toast = spy.new(function() end)

describe("get_curve()", function()
  before_each(function()
    _G.toast:clear()
  end)

  it("returns curve data", function()
    _G.api = spy.new(function()
      return {
        name = "My Curve",
        type = "water",
        data = {
          ["1"] = 1,
          ["5"] = 10,
          ["10"] = 100,
        },
      }
    end)

    local curve = get_curve(1)

    assert.spy(api).was.called()
    assert.spy(api).was.called_with({ url = "/api/curves/1" })

    assert.are_equal("My Curve", curve.name)
    assert.are_equal("water", curve.type)
    assert.are_equal("mL", curve.unit)
    assert.are_equal(1, curve.day(0))
    assert.are_equal(1, curve.day("1"))
    assert.are_equal(1, curve.day(1))
    assert.are_equal(5.5, curve.day(3))
    assert.are_equal(10, curve.day(5))
    assert.are_equal(46, curve.day(7))
    assert.are_equal(100, curve.day(10))
    assert.are_equal(100, curve.day(999))
  end)

  it("returns distance unit", function()
    _G.api = spy.new(function()
      return {
        name = "My Curve",
        type = "spread",
        data = { ["1"] = 0 },
      }
    end)

    local curve = get_curve(1)

    assert.are_equal("mm", curve.unit)
  end)

  it("errors", function()
    _G.api = spy.new(function() end)

    local curve = get_curve(1)

    assert.is_falsy(curve)
    assert.spy(toast).was.called()
    assert.spy(toast).was.called_with("API error. Is your curve ID correct?", "error")
  end)
end)
