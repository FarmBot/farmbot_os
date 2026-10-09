return function()
    local tool_id = get_device("mounted_tool_id")
    if not tool_id then
        return nil
    end

    return get_tool{id = tool_id}
end
