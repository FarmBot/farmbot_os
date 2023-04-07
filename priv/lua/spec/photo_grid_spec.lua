local photo_grid = require("photo_grid")

_G.toast = spy.new(function() end)
_G.os = { exit = spy.new(function() error("exit") end) }
_G.garden_size = spy.new(function() return { x = 2000, y = 1000, z = 3000 } end)

describe("photo_grid()", function()
  before_each(function()
    _G.toast:clear()
  end)

  it("handles missing values", function()
    _G.env = spy.new(function() end)
    _G.grid = spy.new(function() end)

    assert.has_error(function()
      local grid = photo_grid()

      assert.is_falsy(grid)
      assert.spy(toast).was.called_with("You must first run camera calibration", "error")
    end, "exit")
  end)

  it("handles grid error", function()
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
    _G.grid = spy.new(function() end)

    assert.has_error(function()
      local grid = photo_grid()

      assert.is_falsy(grid)
      assert.spy(toast).was_not_called()
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
    _G.grid = spy.new(function(params)
      local total = params.grid_points.x * params.grid_points.y
      return {
        each = spy.new(function(cb) for i = 1, total do cb({}) end end),
        total = total,
      }
    end)

    local grid = photo_grid()

    assert.are.equal(395, grid.y_spacing_mm)
    assert.are.equal(0, grid.y_offset_mm)
    assert.are.equal(197.5, grid.y_grid_start_mm)
    assert.are.equal(605, grid.y_grid_size_mm)
    assert.are.equal(3, grid.y_grid_points)
    assert.are.equal(395, grid.x_spacing_mm)
    assert.are.equal(0, grid.x_offset_mm)
    assert.are.equal(197.5, grid.x_grid_start_mm)
    assert.are.equal(1605, grid.x_grid_size_mm)
    assert.are.equal(6, grid.x_grid_points)
    assert.are.equal(0, grid.z)
    assert.are.equal(18, grid.total)

    local cb = spy.new(function() end)
    grid.each(cb)
    assert.spy(cb).was.called(18)

    assert.spy(toast).was_not_called()
  end)

  it("returns grid with different values", function()
    _G.env = spy.new(function(key)
      local envs = {
        CAMERA_CALIBRATION_total_rotation_angle = 50,
        CAMERA_CALIBRATION_coord_scale = 0.5,
        CAMERA_CALIBRATION_camera_z = 0,
        CAMERA_CALIBRATION_center_pixel_location_x = 640,
        CAMERA_CALIBRATION_center_pixel_location_y = 360,
        CAMERA_CALIBRATION_camera_offset_x = 0,
        CAMERA_CALIBRATION_camera_offset_y = 0,
      }
      return envs[key]
    end)
    _G.grid = spy.new(function(params)
      local total = params.grid_points.x * params.grid_points.y
      return {
        each = spy.new(function(cb) for i = 1, total do cb({}) end end),
        total = total,
      }
    end)

    local grid = photo_grid()

    assert.are.equal(419, grid.y_spacing_mm)
    assert.are.equal(0, grid.y_offset_mm)
    assert.are.equal(209.5, grid.y_grid_start_mm)
    assert.are.equal(581, grid.y_grid_size_mm)
    assert.are.equal(3, grid.y_grid_points)
    assert.are.equal(139, grid.x_spacing_mm)
    assert.are.equal(0, grid.x_offset_mm)
    assert.are.equal(69.5, grid.x_grid_start_mm)
    assert.are.equal(1861, grid.x_grid_size_mm)
    assert.are.equal(15, grid.x_grid_points)
    assert.are.equal(0, grid.z)
    assert.are.equal(45, grid.total)

    local cb = spy.new(function() end)
    grid.each(cb)
    assert.spy(cb).was.called(45)

    assert.spy(toast).was_not_called()
  end)
end)
