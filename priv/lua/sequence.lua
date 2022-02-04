return function(sequence_id, params)
    local body = {}
    local i = 0
    for key, data_value in pairs(params) do
        i = i + 1
        body[i] = {
            kind = "parameter_application",
            args = {label = key, data_value = data_value}
        }
    end
    return rpc({
        kind = "execute",
        args = {sequence_id = sequence_id},
        body = body
    })
end

