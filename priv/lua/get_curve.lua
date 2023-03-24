return function(curve_id)
  local api_curve_data = api({ url = "/api/curves/" .. curve_id })
  if not api_curve_data then
      toast("API error. Is your curve ID correct?", "error")
      return
  end

  function get_day_value(day)
    local day = tonumber(day)
    local day_string = tostring(day)
    local value = api_curve_data.data[day_string]
    if value ~= nil then
      return value
    end

    local data_days = {}
    local i = 0
    for day_key, _ in pairs(api_curve_data.data) do
      i = i + 1
      data_days[i] = tonumber(day_key)
    end
    table.sort(data_days)

    local greater_days = {}
    local i = 0
    for _, k in pairs(data_days) do
      if k > day then
        i = i + 1
        greater_days[i] = k
      end
    end
    table.sort(greater_days)

    local lesser_days = {}
    local i = 0
    for _, k in pairs(data_days) do
      if k < day then
        i = i + 1
        lesser_days[i] = k
      end
    end
    table.sort(lesser_days)

    local prev_day = lesser_days[#lesser_days]
    local next_day = greater_days[1]

    if prev_day == nil then
      local first_day = tostring(math.floor(data_days[1]))
      return api_curve_data.data[first_day]
    end

    if next_day == nil then
      local last_day = tostring(math.floor(data_days[#data_days]))
      return api_curve_data.data[last_day]
    end

    local prev_value = api_curve_data.data[tostring(math.floor(prev_day))]
    local next_value = api_curve_data.data[tostring(math.floor(next_day))]

    local exact_value = (prev_value * (next_day - day) + next_value * (day - prev_day))
      / (next_day - prev_day)
    return tonumber(string.format("%.2f", exact_value))
  end

  local unit
  if api_curve_data.type == "water" then
    unit = "mL"
  else
    unit = "mm"
  end

  local curve = {
    name = api_curve_data.name,
    type = api_curve_data.type,
    unit = unit,
    day = get_day_value,
  }

  return curve
end
