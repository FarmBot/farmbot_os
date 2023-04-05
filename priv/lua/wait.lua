return function(milliseconds, params)
  if not params then params = {} end
  local seconds = milliseconds / 1000
  local job = params.job or "Waiting " .. seconds .. "s"
  local status = params.status or "Waiting"
  local start_time = os.time() * 1000

  if milliseconds < 1000 then
    wait_ms(milliseconds)
  else
    for i = 1, seconds do
      set_job_progress(job, {
        percent = math.floor((i - 1) / seconds * 100),
        status = status,
        time = start_time,
      })
      wait_ms(1000)
    end
    wait_ms(milliseconds % 1000)
    set_job_progress(job, {
      percent = 100,
      status = "Complete",
      time = start_time,
    })
  end
end
