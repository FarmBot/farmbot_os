return function(slot)
    local slot_dir = slot.pullout_direction
    start_time = os.time() * 1000

    -- Checks
    if read_pin(63) == 0 then
        toast("A tool is already mounted to the UTM - there is an electrical connection between UTM pins B and C.", "error")
        return
    elseif get_device("mounted_tool_id") then
        toast("There is already a tool mounted to the UTM - check the **MOUNTED TOOL** dropdown in the Tools panel.", "error")
        return
    elseif slot.pointer_type ~= "ToolSlot" then
        toast("Provided location must be a tool in a slot", "error")
        return
    elseif slot_dir == 0 then
        toast("Tool slot must have a direction", "error")
        return
    elseif slot.gantry_mounted then
        toast("Tool slot cannot be gantry mounted", "error")
        return
    end

    -- Get tool name
    tool = api({
        url = "/api/tools/" .. slot.tool_id
    })

    if not tool then
        toast("API error", "error")
        return
    end

    -- Job progress tracking
    function job(percent, status)
        set_job_progress(
            "Mounting " .. tool.name,
            { percent = percent, status = status, time = start_time }
        )
    end

    -- Safe Z move to above the tool
    job(20, "Retracting Z")
    move{z=safe_z()}
    job(40, "Moving above tool")
    move{x=slot.x, y=slot.y}

    -- Mount the tool
    job(60, "Mounting tool")
    move{z=slot.z}

    -- Pull the tool out of the slot at 50% speed
    job(80, "Pulling tool out")
    if slot_dir == 1 then
        move_absolute(slot.x + 100, slot.y, slot.z, 50)
    elseif slot_dir == 2 then
        move_absolute(slot.x - 100, slot.y, slot.z, 50)
    elseif slot_dir == 3 then
        move_absolute(slot.x, slot.y + 100, slot.z, 50)
    elseif slot_dir == 4 then
        move_absolute(slot.x, slot.y - 100, slot.z, 50)
    end

    -- Check verification pin
    if read_pin(63) == 1 then
        job(80, "Failed")
        toast("Tool mounting failed - no electrical connection between UTM pins B and C.", "error")
        return
    else
        job(100, "Complete")
        update_device({mounted_tool_id = slot.tool_id})
        toast(tool.name .. " mounted", "success")
    end
end
