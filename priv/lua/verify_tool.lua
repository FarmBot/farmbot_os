return function(params)
  params = params or {}
  local mounted_tool_id = get_device("mounted_tool_id")

  if read_pin(63) == 1 then
      toast("No tool detected on the UTM - there is no electrical connection between UTM pins B and C.", "error")
      return false
  end

  if not mounted_tool_id then
      toast("A tool is mounted but FarmBot does not know which one - check the **MOUNTED TOOL** dropdown in the Tools panel.", "error")
      return false
  end

  local mounted_tool = get_tool{id = mounted_tool_id}
  if not mounted_tool then
      toast("Mounted tool not found - check the **MOUNTED TOOL** dropdown in the Tools panel.", "error")
      return false
  end

  if params.name and params.name ~= mounted_tool.name then
      toast("Expected the " .. params.name .. " to be mounted, but the " .. mounted_tool.name .. " is.", "error")
      return false
  end

  if params.type and params.type ~= mounted_tool.type then
      toast("Expected a " .. params.type .. " tool to be mounted, but a " .. mounted_tool.type .. " tool is.", "error")
      return false
  end

  if params.id then
      local expected_mounted_tool = get_tool{id = params.id}
      if not expected_mounted_tool then
        toast("Expected tool not found - check the provided tool ID.", "error")
        return false
      end
      if params.id ~= mounted_tool_id then
        toast("Expected the " .. expected_mounted_tool.name .. " to be mounted, but the " .. mounted_tool.name .. " tool is.", "error")
        return false
      end
  end

  send_message("success", "The " .. mounted_tool.name .. " is mounted on the UTM")
  return true
end
