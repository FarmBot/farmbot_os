return function(ml, params)
    if not params then params = {} end
    local tool_name = params.tool_name or "Watering Nozzle"
    local pin_number = params.pin or 8

    -- Get all tools
    local tools = api({ url = "/api/tools/" })
    if not tools then
        toast("API error", "error")
        return
    end

    -- Pluck the nozzle
    local nozzle, flow_rate
    for key, tool in pairs(tools) do
        if tool.name == tool_name then
            nozzle = tool
            flow_rate = nozzle.flow_rate_ml_per_s
        end
    end

    -- Checks
    if not flow_rate then
        toast('You must have a tool named "' .. tool_name .. '" to use this sequence.', 'error')
        return
    elseif flow_rate == 0 then
        toast("**FLOW RATE (mL/s)** must be greater than 0 for the " .. tool_name .. " tool.", "error")
        return
    elseif ml <= 0 then
        toast("Liquid volume was 0mL. Skipping.", "warn")
        return
    elseif ml > 10000 then
        toast("Liquid volume cannot be more than 10,000mL", "error")
        return
    end

    local seconds = math.floor(ml / flow_rate * 10) / 10
    local start_time = os.time() * 1000
    local status = "Dispensing"
    local job_message = status .. " " .. ml .. "mL"
    local log_message = job_message .. " over " .. seconds .. " seconds"
    function wait_with_progress(seconds)
        if seconds < 1 then
            set_job_progress(job_message, { percent = 0, status = status, time = start_time })
            wait(seconds * 1000)
            return
        end
        for i = 1, math.floor(seconds) do
            set_job_progress(job_message, {
                percent = math.floor((i - 1) / seconds * 100),
                status = status,
                time = start_time,
            })
            wait(1000)
        end
        local remainder = seconds - math.floor(seconds)
        if remainder > 0 then
            wait(math.ceil(remainder * 1000))
        end
    end

    -- Action
    send_message("info", log_message)
    on(pin_number)
    wait_with_progress(seconds)
    off(pin_number)
    set_job_progress(job_message, { percent = 100, status = "Complete", time = start_time })
end
