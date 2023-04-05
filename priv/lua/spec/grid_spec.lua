local grid = require("grid")

_G.toast = spy.new(function() end)
_G.os = { time = function() return 1000 end }
_G.garden_size = spy.new(function() return { x = 2000, y = 1000, z = 3000 } end)

describe("grid()", function()
  before_each(function()
    _G.toast:clear()
  end)

  it("handles incorrect point count input", function()
    local full_grid = grid{
      grid_points = {
        x = 0,
        y = 1,
        z = 1
      },
      spacing = {
        x = 100,
        y = 200,
        z = 0
      },
    }

    assert.are.equal(nil, full_grid)
    assert.spy(toast).was.called_with("Number of points must be greater than 0 for all three axes", "error")
  end)

  it("handles too large grid size", function()
    local full_grid = grid{
      grid_points = {
        x = 2,
        y = 2,
        z = 2
      },
      spacing = {
        x = 10000,
        y = 20000,
        z = 30000
      },
    }

    assert.are.equal(nil, full_grid)
    assert.spy(toast).was.called_with("Grid must not exceed the **AXIS LENGTH** for any axes: "
    .. "10000mm exceeds 2000mm x-axis length. "
    .. "20000mm exceeds 1000mm y-axis length. "
    .. "30000mm exceeds 3000mm z-axis length. ",
    "error")
  end)

  it("returns grid", function()
    local full_grid = grid{
      grid_points = {
        x = 2,
        y = 3,
        z = 1
      },
      spacing = {
        x = 100,
        y = 200,
        z = 0
      },
    }

    assert.are.equal(6, full_grid.total)

    local cb = spy.new(function() end)
    full_grid.each(cb)
    assert.spy(cb).was.called(6)

    assert.spy(toast).was_not_called()
  end)
end)
