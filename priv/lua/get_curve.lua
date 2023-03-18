return function(curve_id)
  api_curve_data = api({ url = "/api/curves/" .. curve_id })
  if not api_curve_data then
      toast("API error. Is your curve ID correct?", "error")
      return
  end

  function get_day_value(day)
    day = tonumber(day)
    day_string = tostring(day)
    value = api_curve_data.data[day_string]
    if value ~= nil then
      return value
    end

    data_days = {}
    i = 0
    for day_key, _ in pairs(api_curve_data.data) do
      i = i + 1
      data_days[i] = tonumber(day_key)
    end
    table.sort(data_days)

    greater_days = {}
    i = 0
    for _, k in pairs(data_days) do
      if k > day then
        i = i + 1
        greater_days[i] = k
      end
    end
    table.sort(greater_days)

    lesser_days = {}
    i = 0
    for _, k in pairs(data_days) do
      if k < day then
        i = i + 1
        lesser_days[i] = k
      end
    end
    table.sort(lesser_days)

    prev_day = lesser_days[#lesser_days]
    next_day = greater_days[1]

    if prev_day == nil then
      first_day = tostring(math.floor(data_days[1]))
      return api_curve_data.data[first_day]
    end

    if next_day == nil then
      last_day = tostring(math.floor(data_days[#data_days]))
      return api_curve_data.data[last_day]
    end

    prev_value = api_curve_data.data[tostring(math.floor(prev_day))]
    next_value = api_curve_data.data[tostring(math.floor(next_day))]

    exact_value = (prev_value * (next_day - day) + next_value * (day - prev_day))
      / (next_day - prev_day)
    return tonumber(string.format("%.2f", exact_value))
  end

  if api_curve_data.type == "water" then
    unit = "mL"
  else
    unit = "mm"
  end

  curve = {
    name = api_curve_data.name,
    type = api_curve_data.type,
    unit = unit,
    day = get_day_value,
  }

  return curve
end
