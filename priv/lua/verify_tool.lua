return function()
  local mounted_tool_id = get_device("mounted_tool_id")

  if read_pin(63) == 1 then
      toast("No tool detected on the UTM - there is no electrical connection between UTM pins B and C.", "error")
      return false
  end

  if not mounted_tool_id then
      toast("A tool is mounted but FarmBot does not know which one - check the **MOUNTED TOOL** dropdown in the Tools panel.", "error")
      return false
  end

  local mounted_tool_name = get_tool{id = mounted_tool_id}.name
  send_message("success", "The " .. mounted_tool_name .. " is mounted on the UTM")
  return true
end
