function round(n) return math.floor(n + 0.5) end

function angleRound(angle)
    local remainder = math.abs(angle % 90)
    if remainder > 45 then
        return 90 - remainder
    else
        return remainder
    end
end

-- Returns an integer that we need to subtract from width/height
-- due to camera rotation issues.
function cropAmount(width, height, angle)
    local absAngle = angleRound(angle or 0)
    if (absAngle > 0) then
        local x = (5.61 - 0.095 * math.pow(absAngle, 2) + 9.06 * absAngle)
        local factor = x / 640
        local longEdge = math.max(width, height)
        local result = round(longEdge * factor)
        return result
    end
    return 0
end

function fwe(key)
    local e = env("CAMERA_CALIBRATION_" .. key)
    if e then
        return tonumber(e)
    else
        toast("You must first run camera calibration", "error")
        os.exit()
    end
end

return function()
  local cam_rotation = fwe("total_rotation_angle")
  local scale = fwe("coord_scale")
  local z = fwe("camera_z")
  local raw_img_size_x_mm = fwe("center_pixel_location_x") * 2 * scale
  local raw_img_size_y_mm = fwe("center_pixel_location_y") * 2 * scale
  local margin_mm = cropAmount(raw_img_size_x_mm, raw_img_size_y_mm, cam_rotation)
  local cropped_img_size_x_mm = raw_img_size_x_mm - margin_mm - 5
  local cropped_img_size_y_mm = raw_img_size_y_mm - margin_mm - 5
  local x_spacing_mm, y_spacing_mm
  if math.abs(cam_rotation) < 45 then
      x_spacing_mm = cropped_img_size_x_mm
      y_spacing_mm = cropped_img_size_y_mm
  else
      x_spacing_mm = cropped_img_size_y_mm
      y_spacing_mm = cropped_img_size_x_mm
  end
  x_spacing_mm = math.max(10, x_spacing_mm)
  y_spacing_mm = math.max(10, y_spacing_mm)
  local x_grid_size_mm = garden_size().x - x_spacing_mm
  local y_grid_size_mm = garden_size().y - y_spacing_mm
  local x_grid_points = math.ceil(x_grid_size_mm / x_spacing_mm) + 1
  local y_grid_points = math.ceil(y_grid_size_mm / y_spacing_mm) + 1
  local x_grid_start_mm = (x_spacing_mm / 2)
  local y_grid_start_mm = (y_spacing_mm / 2)
  local x_offset_mm = fwe("camera_offset_x")
  local y_offset_mm = fwe("camera_offset_y")

  local full_grid = grid{
    grid_points = {
      x = x_grid_points,
      y = y_grid_points,
      z = 1,
    },
    start = {
      x = x_grid_start_mm,
      y = y_grid_start_mm,
      z = z,
    },
    spacing = {
      x = x_spacing_mm,
      y = y_spacing_mm,
      z = 0,
    },
    offset = {
      x = x_offset_mm,
      y = y_offset_mm,
      z = 0,
    },
    ignore_bounds = true,
  }

  if not full_grid then
    os.exit()
  end

  local each = function(callback)
    full_grid.each(function(cell)
      callback({ x = cell.x, y = cell.y, z = cell.z, count = cell.count })
    end)
  end

  return {
      y_spacing_mm = y_spacing_mm,
      y_offset_mm = y_offset_mm,
      y_grid_start_mm = y_grid_start_mm,
      y_grid_size_mm = y_grid_size_mm,
      y_grid_points = y_grid_points,
      x_spacing_mm = x_spacing_mm,
      x_offset_mm = x_offset_mm,
      x_grid_start_mm = x_grid_start_mm,
      x_grid_size_mm = x_grid_size_mm,
      x_grid_points = x_grid_points,
      z = z,
      total = full_grid.total,
      each = each,
  }
end
