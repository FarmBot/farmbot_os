return function(ml, params)
    params = params or {}
    local tool_name = params.tool_name or "Watering Nozzle"
    local pin_number = params.pin or 8

    -- Get flow_rate
    local tool = get_tool{name = tool_name}
    if not tool then
        toast('Tool "' .. tool_name .. '" not found', 'error')
        return
    end
    local flow_rate = tool.flow_rate_ml_per_s

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
    local status = "Dispensing"
    local job_message = status .. " " .. ml .. "mL"
    local log_message = job_message .. " over " .. seconds .. " seconds"

    -- Action
    send_message("info", log_message)
    on(pin_number)
    wait(seconds * 1000, {
        job = job_message,
        status = status,
    })
    off(pin_number)
end
