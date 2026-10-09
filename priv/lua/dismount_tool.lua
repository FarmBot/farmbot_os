return function()
    local tool_id = get_device("mounted_tool_id")
    local start_time = os.time() * 1000

    -- Checks
    if not tool_id then
        toast("No tool is mounted to the UTM", "error")
        return
    end
    if not verify_tool() then
        return
    end

    -- Pluck the tool slot point where the currently mounted tool belongs
    local slot = get_slot_for_tool{id = tool_id}

    -- Get tool name
    local tool_name = get_tool{id = tool_id}.name

    -- Checks
    if not slot then
        toast("No slot found for the currently mounted tool (" .. tool_name .. ") - check the Tools panel", "error")
        return
    end

    local slot_dir = slot.pullout_direction
    if slot_dir == 0 then
        toast("Tool slot must have a direction", "error")
        return
    elseif (slot.mount_stage or 0) ~= 0 then
        toast("Tool slot cannot be axis mounted", "error")
        return
    end

    -- Job progress tracking
    function job(percent, status)
        set_job_progress(
            "Dismounting " .. tool_name,
            { percent = percent, status = status, time = start_time }
        )
    end

    -- Safe Z move to the front of the slot
    job(20, "Retracting Z")
    move{z = safe_z()}

    job(40, "Moving to front of slot")
    if slot_dir == 1 then
        move{x = slot.x + 100, y = slot.y}
    elseif slot_dir == 2 then
        move{x = slot.x - 100, y = slot.y}
    elseif slot_dir == 3 then
        move{x = slot.x, y = slot.y + 100}
    elseif slot_dir == 4 then
        move{x = slot.x, y = slot.y - 100}
    end

    job(60, "Lowering Z")
    move{z = slot.z}

    -- Put the tool in the slot
    job(80, "Putting tool in slot")
    move_absolute(slot.x, slot.y, slot.z, 50)
    if is_demo() then
      update_device({mounted_tool_id = 0})
    end

    -- Dismount tool
    job(90, "Dismounting tool")
    move{z = slot.z + 50}

    -- Check verification pin
    if read_pin(63) == 0 and not is_demo() then
        job(90, "Failed")
        toast("Tool dismounting failed - there is still an electrical connection between UTM pins B and C.", "error")
        return
    else
        job(100, "Complete")
        if not is_demo() then
          update_device({mounted_tool_id = 0})
        end
        toast(tool_name .. " dismounted", "success")
    end
end
