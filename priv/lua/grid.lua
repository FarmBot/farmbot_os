return function(params)
  local x_point_count = params.grid_points.x
  local y_point_count = params.grid_points.y
  local z_point_count = params.grid_points.z
  local x_grid_max_index = x_point_count - 1
  local y_grid_max_index = y_point_count - 1
  local z_grid_max_index = z_point_count - 1
  local start_time = os.time() * 1000

  params.start = params.start or { x = 0, y = 0, z = 0 }
  params.offset = params.offset or { x = 0, y = 0, z = 0 }

  local x = function(x_index)
    return (params.start.x + (params.spacing.x * x_index) - params.offset.x)
  end
  local y = function(y_index)
    return (params.start.y + (params.spacing.y * y_index) - params.offset.y)
  end
  local z = function(z_index)
    return (params.start.z + (params.spacing.z * z_index) - params.offset.z)
  end

  local grid_max_x = x(x_grid_max_index)
  local grid_max_y = y(y_grid_max_index)
  local grid_max_z = z(z_grid_max_index)
  local x_max = garden_size().x
  local y_max = garden_size().y
  local z_max = garden_size().z

  local size_exceeded = ""
  if x_max > 0 and grid_max_x > x_max then
    size_exceeded = size_exceeded .. math.floor(grid_max_x) .. "mm exceeds " .. x_max .. "mm x-axis length. "
  end
  if y_max > 0 and grid_max_y > y_max then
    size_exceeded = size_exceeded .. math.floor(grid_max_y) .. "mm exceeds " .. y_max .. "mm y-axis length. "
  end
  if z_max > 0 and grid_max_z > z_max then
    size_exceeded = size_exceeded .. math.floor(grid_max_z) .. "mm exceeds " .. z_max .. "mm z-axis length. "
  end

  if not params.ignore_empty and (x_point_count <= 0 or y_point_count <= 0 or z_point_count <= 0) then
      toast("Number of points must be greater than 0 for all three axes", "error")
      return
  elseif not params.ignore_bounds and #size_exceeded > 0 then
      toast("Grid must not exceed the **AXIS LENGTH** for any axes: " .. size_exceeded, "error")
      return
  end

  local each = function(callback)
    local count = 0
    for z_grid_index = 0, z_grid_max_index do
      for x_grid_index = 0, x_grid_max_index do
        for y_grid_index = 0, y_grid_max_index do
          count = count + 1
          local y_grid_index_var
          if (x_grid_index % 2) == 0 then
              y_grid_index_var = y_grid_index
          else
              y_grid_index_var = y_grid_max_index - y_grid_index
          end
          callback({
            x = x(x_grid_index),
            y = y(y_grid_index_var),
            z = z(z_grid_index),
            count = count,
          })
        end
      end
    end
  end

  return {
    total = x_point_count * y_point_count * z_point_count,
    each = each,
  }
end
