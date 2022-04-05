return function()
  local mounted_tool_id = get_device("mounted_tool_id")

  if read_pin(63) == 1 then
      send_message("error", "No tool detected on the UTM - there is no electrical connection between UTM pins B and C.", "toast")
      return false
  end

  if not mounted_tool_id then
      send_message("error", "A tool is mounted but FarmBot does not know which one - check the **MOUNTED TOOL** dropdown in the Tools panel.", "toast")
      return false
  end

  local mounted_tool = api({
      method = "get",
      url = "/api/tools/" .. mounted_tool_id
  })
  send_message("success", "The " .. mounted_tool.name .. " is mounted on the UTM")
  return true
end
