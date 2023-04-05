local movement_grid = require("movement_grid")

_G.grid = spy.new(function()
  return {
    each = function(cb) cb({ x = 0, y = 0, z = 0, count = 1 }) end,
    total = 1,
  }
end)_G.set_job_progress = spy.new(function() end)
_G.move_absolute = spy.new(function() end)
_G.os = { time = function() return 1000 end }

describe("movement_grid()", function()
  before_each(function()
    _G.set_job_progress:clear()
    _G.move_absolute:clear()
  end)

  it("returns grid", function()
    local grid = movement_grid{
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
      job = "Test Grid",
      status_message = "Acting",
    }

    local cb = spy.new(function() end)
    grid.each(cb)
    assert.spy(set_job_progress).was.called_with("Test Grid",
        { percent = 100, status = "Acting", time = 1000000 })
    assert.spy(move_absolute).was.called_with(0, 0, 0)
  end)
end)
