return function(params)
  local full_grid = grid(params)
  local start_time = os.time() * 1000

  local each = function(callback)
    full_grid.each(function(cell)
      set_job_progress(params.job, {
        percent = 100 * (cell.count - 0.5) / full_grid.total,
        status = "Moving",
        time = start_time
      })
      move_absolute(cell.x, cell.y, cell.z)
      set_job_progress(params.job, {
          percent = 100 * (cell.count / full_grid.total),
          status = params.status_message,
          time = start_time
      })
      callback({ count = cell.count })
    end)
  end

  return {
    start_time = start_time,
    total = full_grid.total,
    each = each,
  }
end
