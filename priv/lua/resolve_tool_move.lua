return function(input)
    local selector = {id = input.id, name = input.name, type = input.type}
    local tool = get_tool(selector)
    if not tool then
        error("Tool not found")
    end
    local slot = get_slot_for_tool(selector) or {}
    local stage = slot.mount_stage or 0
    local offset = input.offset or {}
    local result = {}

    for key, value in pairs(input) do
        if key ~= "id" and key ~= "name"
            and key ~= "type" and key ~= "offset" then
            result[key] = value
        end
    end

    for index, axis in ipairs({"x", "y", "z"}) do
        if input[axis] ~= nil then
            local mount_offset = 0
            if stage >= index then
                mount_offset = slot["mount_offset_" .. axis] or 0
            end
            result[axis] = input[axis] - mount_offset
                - (tool["effector_offset_" .. axis] or 0)
                + (offset[axis] or 0)
        elseif offset[axis] ~= nil then
            result.offset = result.offset or {}
            result.offset[axis] = offset[axis]
        end
    end

    return result
end
