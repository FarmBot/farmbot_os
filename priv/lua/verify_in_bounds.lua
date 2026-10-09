return function(params)
    local bounds = garden_size()
    local settings = get_firmware_config()
    local negative_z = settings.movement_home_up_z == 1

    local bound_exceeded = ""
    for _, axis in ipairs({"x", "y", "z"}) do
        local coordinate = params[axis]
        local stop_at_home = settings["movement_stop_at_home_" .. axis] == 1
        local stop_at_max = settings["movement_stop_at_max_" .. axis] == 1
        local direction = 1
        if axis == "z" and negative_z then
            direction = -1
        end

        if coordinate then
            local distance = coordinate * direction
            if stop_at_home and distance < 0 then
                if direction == -1 then
                    bound_exceeded = bound_exceeded .. coordinate .. "mm is above 0mm z-axis maximum. "
                else
                    bound_exceeded = bound_exceeded .. coordinate .. "mm is below 0mm " .. axis .. "-axis minimum. "
                end
            elseif stop_at_max and bounds[axis] > 0 and distance > bounds[axis] then
                if direction == -1 then
                    bound_exceeded = bound_exceeded .. coordinate .. "mm is below " .. -bounds.z .. "mm z-axis minimum. "
                else
                    bound_exceeded = bound_exceeded .. coordinate .. "mm exceeds " .. bounds[axis] .. "mm " .. axis .. "-axis length. "
                end
            end
        end
    end

    if #bound_exceeded > 0 then
        toast("The target coordinate is out of bounds: " .. bound_exceeded, "error")
        return false
    end

    return true
end
