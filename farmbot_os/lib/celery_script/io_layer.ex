defmodule Farmbot.OS.IOLayer do
  @behaviour Farmbot.CeleryScript.IOLayer
  import Farmbot.Config, only: [get_config_value: 3, update_config_value: 4]
  alias Farmbot.Firmware.Vec3
  require Farmbot.Logger

  #TODO(Connor) - these instructions are skipped so far:
  # change_ownership(email, new_token)
  # execute_script(farmware)
  # factory_reset(arduino_firmware)
  # install_farmware
  # install_first_party_farmware

  def handle_io(%{kind: :read_status}) do
    Farmbot.BotState.fetch()
    :ok
  end

  def handle_io(%{kind: :sync}) do
    case Farmbot.Asset.fragment_sync(1) do
      :ok -> :ok
      {:error, _} -> {:error, "Sync failed."}
    end
  end

  def handle_io(%{kind: :calibrate, args: %{axis: "all"}}) do
    do_reduce([:z, :y, :x], fn(axis) ->
      calibrate(axis)
    end)
  end

  def handle_io(%{kind: :calibrate, args: %{axis: axis}}) do
    calibrate(axis)
  end

  def handle_io(%{kind: :check_updates, args: %{package: :farmbot_os}}) do
    case Farmbot.System.Updates.check_updates() do
      {:error, reason} -> {:error, reason}
      nil -> :ok
      {%Version{} = version, url} ->
        case Farmbot.System.Updates.download_and_apply_update({version, url}) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def handle_io(%{kind: :emergency_lock}) do
    case Farmbot.Firmware.emergency_lock() do
      {:error, :emergency_lock} ->
        Farmbot.Logger.error(1, "Farmbot is E Stopped")
        :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def handle_io(%{kind: :emergency_unlock}) do
    case Farmbot.Firmware.emergency_unlock do
      :ok ->
        Farmbot.Logger.success 1, "Bot is Successfully unlocked."
        :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def handle_io(%{kind: :execute, args: %{sequence_id: id}}) do
    case Farmbot.Asset.get_sequence_by_id(id) do
      nil -> {:error, "Could not find that sequence. Try syncing."}
      seq -> {:ok, Csvm.AST.decode(seq)}
    end
  end

  def handle_io(%{kind: :factory_reset, args: %{package: :farmbot_os}}) do
    :ok = Farmbot.BotState.enter_maintenance_mode()
    update_config_value(:bool, "settings", "disable_factory_reset", false)
    Farmbot.Logger.warn 1, "Farmbot OS going down for factory reset!"
    Farmbot.System.factory_reset "CeleryScript request."
  end

  def handle_io(%{kind: :find_home, args: %{axis: "all"}}) do
    do_reduce([:z, :y, :x], fn(axis) ->
      find_home(axis)
    end)
  end

  def handle_io(%{kind: :find_home, args: %{axis: axis}}) do
    find_home(axis)
  end

  def handle_io(%{kind: :home, args: %{axis: "all"}}) do
    case Farmbot.Firmware.home_all() do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def handle_io(%{kind: :home, args: %{axis: axis}}) do
    home(axis)
  end

  def handle_io(%{kind: :move_absolute, args: %{speed: speed, location: loc, offset: offset}}) do
    with %Vec3{} = loc <- ast_to_vec3(loc),
         %Vec3{} = offset <- ast_to_vec3(offset) do
           x = loc.x + offset.x
           y = loc.y + offset.y
           z = loc.z + offset.z
           move_absolute(x, y, z, speed)
         end
  end

  def handle_io(%{kind: :move_relative, args: args}) do
    %{location_data: %{position: %{x: cx, y: cy, z: cz}}} = Farmbot.BotState.fetch()
    move_absolute(cx + args.x, cy + args.y, cz + args.z, args.speed)
  end

  def handle_io(%{kind: :power_off}) do
    :ok = Farmbot.BotState.enter_maintenance_mode()
    Farmbot.System.shutdown("CeleryScript request")
    :ok
  end

  def handle_io(ast) do
    IO.puts "#{ast.kind} is not implemented by FarmbotOS yet."
    {:error, "#{ast.kind} is not implemented by FarmbotOS yet."}
  end

  defp move_absolute(x, y, z, speed) do
    speed_x = (speed / 100) * (movement_max_spd(:x)) |> round()
    speed_y = (speed / 100) * (movement_max_spd(:y)) |> round()
    speed_z = (speed / 100) * (movement_max_spd(:z)) |> round()
    Farmbot.Firmware.move_absolute(new_vec3(x, y, z), speed_x, speed_y, speed_z)
    |> case do
      :ok -> :ok
      {:error, reason} -> {:error, "movement error: #{reason}"}
    end
  end

  def calibrate(axis) do
    Farmbot.Firmware.calibrate(axis)
    |> case do
      :ok -> :ok
      {:error, reason} -> {:error, "calibration error: #{reason}"}
    end
  end

  defp find_home(axis) do
    do_find_home(movement_enable_endpoints(axis), encoder_enabled(axis), axis)
  end

  defp do_find_home(false, false, axis) do
    {:error, "Could not find home on #{axis} axis because endpoints and encoders are disabled."}
  end

  defp do_find_home(ep, ec, axis) when ep == true or ec == true do
    Farmbot.Logger.busy 2, "Finding home on #{axis} axis."
    case Farmbot.Firmware.find_home(axis) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp home(axis) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.busy 1, "Moving to (0, 0, 0)"
    end

    case Farmbot.Firmware.home(axis) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp movement_enable_endpoints(axis) do
    case get_config_value(:float, "hardware_params", "movement_enable_endpoints_#{axis}") do
      nil -> false
      0 -> false
      1 -> true
    end
  end

  defp encoder_enabled(axis) do
    case get_config_value(:float, "hardware_params", "encoder_enabled_#{axis}") do
      nil -> false
      0 -> false
      1 -> true
    end
  end

  defp movement_max_spd(axis) do
    get_config_value(:float, "hardware_params", "movement_max_spd_#{axis}") || 1.0
  end

  defp new_vec3(x, y, z) do
    Vec3.new(x, y, z)
  end

  defp ast_to_vec3(%{kind: :coordinate, args: %{x: x, y: y, z: z}}) do
    new_vec3(x, y, z)
  end

  defp ast_to_vec3(ast) do
    {:error, "Cannont convert #{inspect ast} to vec3"}
  end

  defp do_reduce([arg | rest], fun) do
    case fun.(arg) do
      :ok -> do_reduce(rest, fun)
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_reduce([], _) do
    :ok
  end
end
