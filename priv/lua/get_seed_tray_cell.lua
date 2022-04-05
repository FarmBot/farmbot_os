return function(tray, tray_cell)
  local cell = string.upper(tray_cell)
  local seeder_needle_offset = 17.5
  local cell_spacing = 12.5
  local cells = {
      A1 = {label = "A1", x = 0, y = 0},
      A2 = {label = "A2", x = 0, y = 1},
      A3 = {label = "A3", x = 0, y = 2},
      A4 = {label = "A4", x = 0, y = 3},
      B1 = {label = "B1", x = -1, y = 0},
      B2 = {label = "B2", x = -1, y = 1},
      B3 = {label = "B3", x = -1, y = 2},
      B4 = {label = "B4", x = -1, y = 3},
      C1 = {label = "C1", x = -2, y = 0},
      C2 = {label = "C2", x = -2, y = 1},
      C3 = {label = "C3", x = -2, y = 2},
      C4 = {label = "C4", x = -2, y = 3},
      D1 = {label = "D1", x = -3, y = 0},
      D2 = {label = "D2", x = -3, y = 1},
      D3 = {label = "D3", x = -3, y = 2},
      D4 = {label = "D4", x = -3, y = 3}
  }

  -- Checks
  if tray.pointer_type ~= "ToolSlot" then
      send_message("error", "Seed Tray variable must be a seed tray in a slot", "toast")
      return
  elseif not cells[cell] then
      send_message("error", "Seed Tray Cell must be one of **A1** through **D4**", "toast")
      return
  end

  -- Flip X offsets depending on pullout direction
  local flip = 1
  if tray.pullout_direction == 1 then
      flip = 1
  elseif tray.pullout_direction == 2 then
      flip = -1
  else
      send_message("error", "Seed Tray **SLOT DIRECTION** must be `Positive X` or `Negative X`")
      return
  end

  -- A1 coordinates
  local A1 = {
      x = tray.x - seeder_needle_offset + (1.5 * cell_spacing * flip),
      y = tray.y - (1.5 * cell_spacing * flip),
      z = tray.z
  }

  -- Cell offset from A1
  local offset = {
      x = cell_spacing * cells[cell].x * flip,
      y = cell_spacing * cells[cell].y * flip
  }

  -- Return cell coordinates
  return {
      x = A1.x + offset.x,
      y = A1.y + offset.y,
      z = A1.z
  }
end
