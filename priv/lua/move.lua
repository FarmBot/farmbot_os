function axis_overwrite(axis, num)
    return {
        kind = "axis_overwrite",
        args = {
            axis = axis,
            axis_operand = {kind = "numeric", args = {number = num}}
        }
    }
end

function speed_overwrite(axis, num)
    return {
        kind = "speed_overwrite",
        args = {
            axis = axis,
            speed_setting = {kind = "numeric", args = {number = num}}
        }
    }
end

function axis_order(params)
    local grouping = params.grouping or "xyz"
    local route = params.route or "in_order"
    return { kind = "axis_order", args = { grouping = grouping, route = route } }
end

function move_body(input)
    local body = {}

    if input.x then body[#body + 1] = axis_overwrite("x", input.x) end
    if input.y then body[#body + 1] = axis_overwrite("y", input.y) end
    if input.z then body[#body + 1] = axis_overwrite("z", input.z) end
    if input.speed then body[#body + 1] = speed_overwrite("x", input.speed) end
    if input.speed then body[#body + 1] = speed_overwrite("y", input.speed) end
    if input.speed then body[#body + 1] = speed_overwrite("z", input.speed) end
    if input.grouping or input.route then body[#body + 1] = axis_order(input) end
    if input.safe_z then body[#body + 1] = {kind = "safe_z", args = {}} end

    return body
end

return function(input)
    cs_eval({
        kind = "rpc_request",
        args = {label = "move_cmd_lua", priority = 500},
        body = {
            {
                kind = "move",
                args = {},
                body = move_body(input)
            }
        }
    })
end
