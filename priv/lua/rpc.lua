return function(rpc_node)
    local label = "" .. math.random() .. math.random();
    return cs_eval({
        kind = "rpc_request",
        args = {label = label},
        body = {rpc_node}
    })
end
