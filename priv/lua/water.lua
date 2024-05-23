return function(plant, params)
    local plant_name_xy = plant.name .. " at (" .. plant.x .. ", " .. plant.y .. ")"
    local job_name = "Watering " .. plant_name_xy

    if not plant.age and not plant.planted_at then
        toast(plant_name_xy .. " has not been planted yet. Skipping.", "warn")
        return
    end

    if plant.age then
      plant_age = plant.age
    else
      plant_age = math.ceil((os.time() - to_unix(plant.planted_at)) / 86400)
    end

    -- Get water curve and water amount in mL
    local water_curve, water_ml
    if plant.water_curve_id then
        water_curve = get_curve(plant.water_curve_id)
        water_ml = water_curve.day(plant_age)
    else
        toast(plant_name_xy .. " has no assigned water curve. Skipping.", "warn")
        return
    end

    -- Move to the plant
    set_job(job_name, { status = "Moving" })
    move{ x = plant.x, y = plant.y, z = safe_z() }

    -- Water the plant
    set_job(job_name, { status = "Watering", percent = 50 })
    send_message("info", "Watering " .. plant_age .. " day old " .. plant_name_xy .. " " .. water_ml .. "mL")
    dispense(water_ml, params)
    complete_job(job_name)
end
