local safe_z = get_fbos_config("safe_z")

function overwrite(axis, num)
    return {
        kind = "axis_overwrite",
        args = {
            axis = axis,
            axis_operand = {kind = "numeric", args = {number = num}}
        }
    }
end

return function(input)
    local speed = input.speed or 100
    local pos = get_position()
    if input.safe_z then
        cs_eval({
            kind = "rpc_request",
            args = {label = "safe_z_lua", priority = 500},
            body = {
                {
                    kind = "move",
                    args = {},
                    body = {
                        overwrite("x", input.x or pos.x),
                        overwrite("y", input.y or pos.y),
                        overwrite("z", input.z or pos.z),
                        {kind = "safe_z", args = {}}
                    }
                }
            }
        })
    else
        return move_absolute(input, speed)
    end
end
