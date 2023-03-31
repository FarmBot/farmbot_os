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
        toast("**FLOW RATE (mL/s)** must be greater than 0 for the " .. tool_name .. " tool. Refer to the sequence description for setup instructions.", "error")
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
    local message = "Dispensing " .. ml .. "mL over " .. seconds .. " seconds"
    local status = "Dispensing"
    function wait_with_progress(milliseconds)
        for i = 1, 10 do
            set_job_progress(message, {
                percent = (i - 1) * 10,
                status = status,
                time = start_time,
            })
            wait(milliseconds / 10)
        end
    end

    -- Action
    send_message("info", message)
    on(pin_number)
    wait_with_progress(seconds * 1000)
    off(pin_number)
    set_job_progress(message, { percent = 100, status = "Complete", time = start_time })
end
