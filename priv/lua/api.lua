function merge(t1, t2)
    for k, v in ipairs(t2) do table.insert(t1, v) end
    return t1
end

return function(input)
    params = {
        headers = {
            Authorization = ("bearer " .. auth_token()),
            Accept = "application/json"
        }
    }
    params.method = input.method or "GET"
    if input.url then
        params.url = __SERVER_PATH .. input.url
    else
        send_message("error", "Missing URL in HTTP request")
        return
    end

    if input.body then params.body = json.encode(input.body) end

    if input.headers then merge(params.headers, input.headers) end

    local result, error = http(params)
    if error then
        send_message("error", "NETWORK ERROR: " .. inspect(error))
        return
    else
        if result.status > 299 then
            send_message("error", "HTTP ERROR: " .. inspect(result))
            return
        else
            return json.decode(result.body)
        end
    end
end
