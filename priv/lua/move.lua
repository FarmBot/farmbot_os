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

return function(input)
    cs_eval({
        kind = "rpc_request",
        args = {label = "move_cmd_lua", priority = 500},
        body = {
            {
                kind = "move",
                args = {},
                body = {
                    input.x and axis_overwrite("x", input.x),
                    input.y and axis_overwrite("y", input.y),
                    input.z and axis_overwrite("z", input.z),
                    input.speed and speed_overwrite("x", input.speed),
                    input.speed and speed_overwrite("y", input.speed),
                    input.speed and speed_overwrite("z", input.speed),
                    input.safe_z and {kind = "safe_z", args = {}}
                }
            }
        }
    })
end
