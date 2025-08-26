defmodule FarmbotOS.Lua.DataManipulation do
  @moduledoc """
  Extensions for manipulating data from Lua
  """

  alias FarmbotOS.{Asset, JSON}
  alias FarmbotOS.Asset.{Repo, Tool, Device, FbosConfig, FirmwareConfig}
  alias FarmbotOS.Lua.Util
  alias FarmbotOS.Lua
  alias FarmbotOS.SysCalls.ResourceUpdate
  alias FarmbotOS.HTTP
  alias FarmbotOS.Celery.SpecialValue
  require FarmbotOS.Logger

  @methods %{
    "connect" => :connect,
    "delete" => :delete,
    "get" => :get,
    "head" => :head,
    "options" => :options,
    "patch" => :patch,
    "post" => :post,
    "put" => :put,
    "trace" => :trace
  }

  def http([lua_config], lua) do
    config = Util.lua_to_elixir(lua_config)
    url = Map.fetch!(config, "url")
    method_str = String.downcase(Map.get(config, "method", "get")) || "get"
    method = Map.get(@methods, method_str, :get)
    headers = Map.to_list(Map.get(config, "headers", %{}))
    body = Map.get(config, "body", "")
    options = [{:recv_timeout, 180_000}]
    hackney = HTTP.hackney()

    # Example request:
    #     {:ok, 200,
    #    [
    #      {"Access-Control-Allow-Origin", "*"},
    #      {"Content-Length", "33"},
    #      {"Content-Type", "application/json; charset=utf-8"},
    #    ], #Reference<0.3657984643.824705025.36946>}
    # }
    with {:ok, status, resp_headers, client_ref} <-
           hackney.request(method, url, headers, body, options),
         # Example response body: {:ok, "{\"whatever\": \"foo_bar_baz\"}"}
         {:ok, resp_body} <- hackney.body(client_ref) do
      result = %{
        body: resp_body,
        headers: Map.new(resp_headers),
        status: status
      }

      {[Util.map_to_table(result)], lua}
    else
      error ->
        FarmbotOS.Logger.error(3, inspect(error))
        {[nil, "HTTP CLIENT ERROR - See log for details"], lua}
    end
  end

  def env([key, value], lua) do
    with :ok <- FarmbotOS.SysCalls.set_user_env(key, value) do
      {[value], lua}
    else
      {:error, reason} ->
        {[nil, reason], lua}

      error ->
        {[nil, inspect(error)], lua}
    end
  end

  def env([key], lua) do
    result =
      Asset.list_farmware_env()
      |> Enum.map(fn e -> {e.key, e.value} end)
      |> Map.new()
      |> Map.get(key)

    {[result], lua}
  end

  def json_encode([data], lua) do
    with {:ok, json} <- JSON.encode(Util.lua_to_elixir(data)) do
      {[json], lua}
    else
      _ -> {[nil, "Error serializing JSON."], lua}
    end
  end

  def json_decode([data], lua) do
    with {:ok, map} <- JSON.decode(data) do
      {[Util.map_to_table(map)], lua}
    else
      _ -> {[nil, "Error parsing JSON."], lua}
    end
  end

  def update_device([table], lua) do
    params = Map.new(table)

    new_params =
      if Map.has_key?(params, "mounted_tool_id") do
        if params["mounted_tool_id"] == 0 do
          Map.put(params, "mounted_tool_id", nil)
        else
          tool_ids = Repo.all(Tool) |> Enum.map(fn tool -> tool.id end)

          if not Enum.member?(tool_ids, params["mounted_tool_id"]) do
            FarmbotOS.Logger.error(3, "Tool ID not found.")

            Enum.filter(params, fn {key, _value} -> key != "mounted_tool_id" end)
            |> Map.new()
          else
            params
          end
        end
      else
        params
      end

    _ = ResourceUpdate.update_resource("Device", nil, new_params)
    {[true], lua}
  end

  def get_device([field], lua) do
    device = Asset.device() |> Device.render()
    {[device[String.to_atom(field)]], lua}
  end

  def get_device(_, lua) do
    device = Asset.device() |> Device.render()
    {[Util.map_to_table(device)], lua}
  end

  def update_fbos_config([table], lua) do
    Map.new(table)
    |> Asset.update_fbos_config!()
    |> Asset.Private.mark_dirty!(%{})

    {[true], lua}
  end

  def get_fbos_config([field], lua) do
    fbos_config = Asset.fbos_config() |> FbosConfig.render()
    {[fbos_config[String.to_atom(field)]], lua}
  end

  def get_fbos_config(_, lua) do
    conf =
      Asset.fbos_config()
      |> FbosConfig.render()
      |> Util.map_to_table()

    {[conf], lua}
  end

  def safe_z(_args, lua) do
    get_fbos_config(["safe_height"], lua)
  end

  def update_firmware_config([table], lua) do
    Map.new(table)
    |> Asset.update_firmware_config!()
    |> Asset.Private.mark_dirty!(%{})

    {[true], lua}
  end

  def get_firmware_config([field], lua) do
    firmware_config = Asset.firmware_config() |> FirmwareConfig.render()
    {[firmware_config[String.to_atom(field)]], lua}
  end

  def get_firmware_config(_, lua) do
    firmware_config = Asset.firmware_config() |> FirmwareConfig.render()
    {[Util.map_to_table(firmware_config)], lua}
  end

  def get_tool([params], lua) do
    map = Util.lua_to_elixir(params)

    tool_id = Map.get(map, "id")
    tool_name = Map.get(map, "name")
    tool_params = %{}

    tool_params =
      if tool_id do
        Map.put(tool_params, :id, tool_id)
      else
        tool_params
      end

    tool_params =
      if tool_name do
        Map.put(tool_params, :name, tool_name)
      else
        tool_params
      end

    tool = Asset.get_tool(tool_params)

    tool_result =
      if tool do
        %{
          id: tool.id,
          name: tool.name,
          seeder_tip_z_offset: tool.seeder_tip_z_offset,
          flow_rate_ml_per_s: tool.flow_rate_ml_per_s
        }
      else
        nil
      end

    {[tool_result], lua}
  end

  defp drop_fields(point) do
    point
    |> Map.drop([
      :__meta__,
      :__struct__,
      :local_id,
      :local_meta,
      :discarded_at,
      :gantry_mounted,
      :pullout_direction,
      :monitor
    ])
  end

  def get_weeds([], lua) do
    get_weeds([%{}], lua)
  end

  def get_weeds([params], lua) do
    weeds =
      Asset.get_all_points_by_type("Weed")
      |> Enum.map(fn weed ->
        weed
        |> Map.put(:age, calculate_age(weed.created_at))
        |> format_field_as_iso8601(:created_at)
        |> format_field_as_iso8601(:updated_at)
      end)
      |> Enum.filter(&filter_point(&1, params, "active"))
      |> Enum.map(&drop_fields/1)

    {[weeds], lua}
  end

  defp calculate_age(nil), do: nil

  defp calculate_age(planted_at) do
    days =
      DateTime.diff(DateTime.utc_now(), planted_at, :second)
      |> Kernel./(86400)
      |> Float.ceil()
      |> trunc()

    days
  end

  defp format_field_as_iso8601(map, field) do
    case Map.get(map, field) do
      nil -> map
      value -> Map.put(map, field, DateTime.to_iso8601(value))
    end
  end

  defp filter_point(point, params, stage) do
    map = Util.lua_to_elixir(params)

    plant_stage = Map.get(map, "plant_stage") || stage
    openfarm_slug = Map.get(map, "openfarm_slug")
    min_radius = Map.get(map, "min_radius")
    max_radius = Map.get(map, "max_radius")
    min_age = Map.get(map, "min_age")
    max_age = Map.get(map, "max_age")
    color = Map.get(map, "color")
    at_soil_level = Map.get(map, "at_soil_level")

    (is_nil(plant_stage) or point.plant_stage == plant_stage) and
      (is_nil(openfarm_slug) or
         point.openfarm_slug == String.downcase(openfarm_slug)) and
      (is_nil(min_radius) or point.radius >= min_radius) and
      (is_nil(max_radius) or point.radius <= max_radius) and
      (is_nil(min_age) or point.age >= min_age) and
      (is_nil(max_age) or point.age <= max_age) and
      (is_nil(color) or point.meta["color"] == color) and
      (is_nil(at_soil_level) or
         point.meta["at_soil_level"] == at_soil_level or
         (at_soil_level == "false" and point.meta["at_soil_level"] == nil))
  end

  def get_plants([], lua) do
    get_plants([%{}], lua)
  end

  def get_plants([params], lua) do
    plants =
      Asset.get_all_points_by_type("Plant")
      |> Enum.map(fn plant ->
        plant
        |> Map.put(:age, calculate_age(plant.planted_at))
        |> format_field_as_iso8601(:planted_at)
        |> format_field_as_iso8601(:created_at)
        |> format_field_as_iso8601(:updated_at)
      end)
      |> Enum.filter(&filter_point(&1, params, "planted"))
      |> Enum.map(&drop_fields/1)

    {[plants], lua}
  end

  def get_generic_points([], lua) do
    get_generic_points([%{}], lua)
  end

  def get_generic_points([params], lua) do
    points =
      Asset.get_all_points_by_type("GenericPointer")
      |> Enum.map(fn point ->
        point
        |> Map.put(:age, calculate_age(point.created_at))
        |> format_field_as_iso8601(:created_at)
        |> format_field_as_iso8601(:updated_at)
      end)
      |> Enum.filter(&filter_point(&1, params, nil))
      |> Enum.map(&drop_fields/1)

    {[points], lua}
  end

  def new_sensor_reading([table], lua) do
    table
    |> Enum.map(fn
      {"mode", val} -> {"mode", round(val)}
      {"pin", val} -> {"pin", round(val)}
      {"value", val} -> {"value", round(val)}
      other -> other
    end)
    |> Map.new()
    |> Asset.new_sensor_reading!()

    {[true], lua}
  end

  defp get_points_via_group(id_or_name) do
    key =
      cond do
        is_integer(id_or_name) -> {:id, id_or_name}
        is_binary(id_or_name) -> {:name, id_or_name}
        true -> nil
      end

    case key do
      {field, value} ->
        case Asset.Repo.get_by(Asset.PointGroup, [{field, value}]) do
          %{sort_type: sort_by} = point_group ->
            Asset.CriteriaRetriever.run(point_group)
            |> Asset.sort_points(sort_by || "xy_ascending")

          _ ->
            []
        end

      _ ->
        []
    end
  end

  def get_group([group_id_or_name], lua) do
    points =
      get_points_via_group(group_id_or_name)
      |> Enum.map(fn point ->
        point
        |> Map.put(
          :age,
          calculate_age(
            if point.pointer_type == "Plant",
              do: point.planted_at,
              else: point.created_at
          )
        )
        |> format_field_as_iso8601(:planted_at)
        |> format_field_as_iso8601(:created_at)
        |> format_field_as_iso8601(:updated_at)
      end)
      |> Enum.map(&drop_fields/1)

    {[points], lua}
  end

  def group([group_id], lua) do
    point_group = Asset.find_points_via_group(group_id)

    if point_group do
      point_ids = point_group.point_ids
      {[point_ids], lua}
    else
      {[[]], lua}
    end
  end

  def sort([list, sort_method], lua) do
    list = Util.lua_to_elixir(list)
    is_id_list = Enum.all?(list, fn x -> is_integer(x) end)

    points =
      if is_id_list do
        Enum.map(list, fn id -> Asset.get_point(id: id) end)
      else
        list
      end

    ordered =
      points
      |> Enum.map(&drop_fields/1)
      |> Enum.map(fn p ->
        for {k, v} <- p, into: %{} do
          key =
            case k do
              k when is_atom(k) -> k
              k when is_binary(k) -> String.to_atom(k)
              _ -> k
            end

          {key, v}
        end
      end)
      |> Asset.sort_points(sort_method)

    ordered =
      if is_id_list do
        Enum.map(ordered, fn p -> p.id end)
      else
        ordered
      end

    {[Util.map_to_table(ordered)], lua}
  end

  def soil_height([x, y], lua),
    do: {[SpecialValue.soil_height(%{x: x, y: y})], lua}

  def b64_decode([data], lua) when is_bitstring(data) do
    {:ok, result} = Base.decode64(data)
    {[result], lua}
  end

  def b64_encode([data], lua) when is_bitstring(data) do
    {[Base.encode64(data)], lua}
  end

  def garden_size(_data, lua) do
    p = FarmbotOS.BotState.fetch().mcu_params

    result = %{
      z: (p.movement_axis_nr_steps_z || 0) / (p.movement_step_per_mm_z || 1),
      y: (p.movement_axis_nr_steps_y || 0) / (p.movement_step_per_mm_y || 1),
      x: (p.movement_axis_nr_steps_x || 0) / (p.movement_step_per_mm_x || 1)
    }

    {[Util.map_to_table(result)], lua}
  end

  def take_photo([], lua), do: take_photo_p(lua, %{})

  def take_photo([args], lua) do
    {:ok, json_args_string} = JSON.encode(Util.lua_to_elixir(args))

    env = %{
      take_photo_args: json_args_string
    }

    take_photo_p(lua, env)
  end

  def take_photo([width, height], lua) do
    env = %{
      take_photo_width: width,
      take_photo_height: height
    }

    take_photo_p(lua, env)
  end

  def take_photo([width, height, args], lua) do
    {:ok, json_args_string} = JSON.encode(Util.lua_to_elixir(args))

    env = %{
      take_photo_width: width,
      take_photo_height: height,
      take_photo_args: json_args_string
    }

    take_photo_p(lua, env)
  end

  defp take_photo_p(lua, env) do
    env = Map.new(env, fn {k, v} -> {to_string(k), to_string(v)} end)

    case FarmbotOS.SysCalls.Farmware.execute_script("take-photo", env) do
      {:error, reason} -> {[reason], lua}
      :ok -> {[], lua}
      other -> {[inspect(other)], lua}
    end
  end

  def take_photo_raw([], lua), do: take_photo_raw_p(lua, 800, 800, [])

  def take_photo_raw([args], lua),
    do: take_photo_raw_p(lua, 800, 800, Util.lua_to_elixir(args))

  def take_photo_raw([width, height], lua),
    do: take_photo_raw_p(lua, width, height, [])

  def take_photo_raw([width, height, args], lua),
    do: take_photo_raw_p(lua, width, height, Util.lua_to_elixir(args))

  # Output is jpg encoded string.
  # Optionally emits an error.
  defp take_photo_raw_p(lua, width, height, args) do
    {data, resp} =
      System.cmd(
        "fswebcam",
        args ++
          [
            "-r",
            "#{width}x#{height}",
            "-S",
            "10",
            "--no-banner",
            "--log",
            "/dev/null",
            "--save",
            "-"
          ]
      )

    case resp do
      0 ->
        {[data, nil], lua}

      _ ->
        {[nil, data], lua}
    end
  end

  def photo_grid(args, lua), do: lua_extension(args, lua, "photo_grid")
  def api(args, lua), do: lua_extension(args, lua, "api")
  def rpc(args, lua), do: lua_extension(args, lua, "rpc")
  def sequence(args, lua), do: lua_extension(args, lua, "sequence")
  def verify_tool(args, lua), do: lua_extension(args, lua, "verify_tool")
  def get_curve(args, lua), do: lua_extension(args, lua, "get_curve")
  def dispense(args, lua), do: lua_extension(args, lua, "dispense")
  def water(args, lua), do: lua_extension(args, lua, "water")
  def grid(args, lua), do: lua_extension(args, lua, "grid")
  def wait(args, lua), do: lua_extension(args, lua, "wait")

  def get_seed_tray_cell(args, lua),
    do: lua_extension(args, lua, "get_seed_tray_cell")

  def lua_extension(args, lua, filename) do
    lua_code = File.read!("#{:code.priv_dir(:farmbot)}/lua/#{filename}.lua")

    with {:ok, [result]} <- Lua.raw_eval(lua, lua_code) do
      if is_function(result) do
        {result.(args), lua}
      else
        {[result], lua}
      end
    else
      error ->
        {[nil, "ERROR: #{inspect(error)}"], lua}
    end
  end
end
