defmodule FarmbotOS.Lua.DataManipulation do
  @moduledoc """
  Extensions for manipulating data from Lua
  """

  alias FarmbotOS.{Asset, JSON}
  alias FarmbotOS.Asset.{Device, FbosConfig, FirmwareConfig}
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
    options = [{:timeout, 180_000}]
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
    _ = ResourceUpdate.update_resource("Device", nil, params)
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

  def group([group_id], lua) do
    point_group = Asset.find_points_via_group(group_id)

    if point_group do
      points = point_group.point_ids
      {[points], lua}
    else
      {[[]], lua}
    end
  end

  def sort([point_ids, sort_method], lua) do
    points =
      point_ids
      |> Enum.map(fn {_, id} -> Asset.get_point(id: id) end)

    ordered =
      Asset.sort_points(points, sort_method)
      |> Enum.map(fn p -> p.id end)

    {[ordered], lua}
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
