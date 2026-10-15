return function(input)
    local selector = {id = input.id, name = input.name, type = input.type}
    local tool = get_tool(selector)
    if not tool then
        error("Tool not found")
    end
    local slot = get_slot_for_tool(selector) or {}
    local stage = slot.mount_stage or 0
    local offset = input.offset or {}
    local body = {}

    for key, value in pairs(input) do
        body[key] = value
    end
    body.offset = {}

    for index, axis in ipairs({"x", "y", "z"}) do
        local mount_offset = 0
        if stage >= index then
            mount_offset = slot["mount_offset_" .. axis] or 0
        end
        body.offset[axis] = -mount_offset
            - (tool["effector_offset_" .. axis] or 0)
            + (offset[axis] or 0)
    end

    move(body)
end
