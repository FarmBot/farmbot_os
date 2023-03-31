return function(plant, params)
    local plant_xyz = "(" .. plant.x .. ", " .. plant.y .. ", " .. plant.z .. ")"

    -- Get water curve and water amount in mL
    local water_curve, water_ml
    if plant.water_curve_id then
        water_curve = get_curve(plant.water_curve_id)
        water_ml = water_curve.day(plant.age)
    else
        toast(plant.name .. " at " .. plant_xyz .. " has no assigned water curve. Skipping.", "warn")
        return
    end

    send_message("info", "Watering " .. plant.age .. " day old " .. plant.name .. " at " .. plant_xyz .. " " .. water_ml .. "mL")
    dispense(water_ml, params)
end
