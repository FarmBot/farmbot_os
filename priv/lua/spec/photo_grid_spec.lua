local photo_grid = require("photo_grid")

_G.toast = spy.new(function() end)
_G.os = { exit = spy.new(function() error("exit") end) }
_G.garden_size = spy.new(function() return { x = 2000, y = 1000 } end)

describe("photo_grid()", function()
  before_each(function()
    _G.toast:clear()
  end)

  it("handles missing values", function()
    _G.env = spy.new(function() end)

    assert.has_error(function()
      local grid = photo_grid()

      assert.is_falsy(grid)
      assert.spy(toast).was.called_with("You must first run camera calibration", "error")
    end, "exit")
  end)

  it("returns grid", function()
    _G.env = spy.new(function(key)
      local envs = {
        CAMERA_CALIBRATION_total_rotation_angle = 0,
        CAMERA_CALIBRATION_coord_scale = 1,
        CAMERA_CALIBRATION_camera_z = 0,
        CAMERA_CALIBRATION_center_pixel_location_x = 200,
        CAMERA_CALIBRATION_center_pixel_location_y = 200,
        CAMERA_CALIBRATION_camera_offset_x = 0,
        CAMERA_CALIBRATION_camera_offset_y = 0,
      }
      return envs[key]
    end)

    local grid = photo_grid()

    assert.are.equal(400, grid.y_spacing_mm)
    assert.are.equal(0, grid.y_offset_mm)
    assert.are.equal(200, grid.y_grid_start_mm)
    assert.are.equal(600, grid.y_grid_size_mm)
    assert.are.equal(3, grid.y_grid_points)
    assert.are.equal(400, grid.x_spacing_mm)
    assert.are.equal(0, grid.x_offset_mm)
    assert.are.equal(200, grid.x_grid_start_mm)
    assert.are.equal(1600, grid.x_grid_size_mm)
    assert.are.equal(5, grid.x_grid_points)
    assert.are.equal(0, grid.z)
    assert.are.equal(15, grid.total)

    local cb = spy.new(function() end)
    grid.each(cb)
    assert.spy(cb).was.called(15)

    assert.spy(toast).was_not_called()
  end)

  it("returns grid with different values", function()
    _G.env = spy.new(function(key)
      local envs = {
        CAMERA_CALIBRATION_total_rotation_angle = 50,
        CAMERA_CALIBRATION_coord_scale = 1,
        CAMERA_CALIBRATION_camera_z = 0,
        CAMERA_CALIBRATION_center_pixel_location_x = 200,
        CAMERA_CALIBRATION_center_pixel_location_y = 200,
        CAMERA_CALIBRATION_camera_offset_x = 0,
        CAMERA_CALIBRATION_camera_offset_y = 0,
      }
      return envs[key]
    end)

    local grid = photo_grid()

    assert.are.equal(265, grid.y_spacing_mm)
    assert.are.equal(0, grid.y_offset_mm)
    assert.are.equal(132.5, grid.y_grid_start_mm)
    assert.are.equal(735, grid.y_grid_size_mm)
    assert.are.equal(4, grid.y_grid_points)
    assert.are.equal(265, grid.x_spacing_mm)
    assert.are.equal(0, grid.x_offset_mm)
    assert.are.equal(132.5, grid.x_grid_start_mm)
    assert.are.equal(1735, grid.x_grid_size_mm)
    assert.are.equal(8, grid.x_grid_points)
    assert.are.equal(0, grid.z)
    assert.are.equal(32, grid.total)

    local cb = spy.new(function() end)
    grid.each(cb)
    assert.spy(cb).was.called(32)

    assert.spy(toast).was_not_called()
  end)
end)
