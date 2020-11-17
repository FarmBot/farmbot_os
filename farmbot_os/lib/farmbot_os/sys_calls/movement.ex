defmodule FarmbotOS.SysCalls.Movement do
  @moduledoc false

  require FarmbotCore.Logger

  def get_current_x do
    get_position(:x)
  end

  def get_current_y do
    get_position(:y)
  end

  def get_current_z do
    get_position(:z)
  end

  def get_cached_x do
    get_cached_position(:x)
  end

  def get_cached_y do
    get_cached_position(:y)
  end

  def get_cached_z do
    get_cached_position(:z)
  end

  def zero(axis) do
    axis = assert_axis!(axis)

    case FarmbotFirmware.command({:position_write_zero, [axis]}) do
      :ok ->
        :ok

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("zero()", reason)
    end
  end

  def get_position() do
    case FarmbotFirmware.request({nil, {:position_read, []}}) do
      {:ok, {_, {:report_position, params}}} ->
        params

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("get_position", reason)
    end
  end

  def get_position(axis) do
    axis = assert_axis!(axis)

    case get_position() do
      {:error, _} = error -> error
      position -> Keyword.fetch!(position, axis)
    end
  end

  def get_cached_position() do
    %{x: x, y: y, z: z} = FarmbotCore.BotState.fetch().location_data.position
    [x: x, y: y, z: z]
  end

  def get_cached_position(axis) do
    axis = assert_axis!(axis)
    Keyword.fetch!(get_cached_position(), axis)
  end

  def move_absolute(x, y, z, speed) do
    do_move_absolute(x, y, z, speed, speed, speed)
  end

  def move_absolute(x, y, z, speed_x, speed_y, speed_z) do
    do_move_absolute(x, y, z, speed_x, speed_y, speed_z)
  end

  defp do_move_absolute(x, y, z, speed_x, speed_y, speed_z) do
    with {:ok, max_speed_x} <- param_read(:movement_max_spd_x),
         {:ok, max_speed_y} <- param_read(:movement_max_spd_y),
         {:ok, max_speed_z} <- param_read(:movement_max_spd_z),
         params <- [
           x: x / 1.0,
           y: y / 1.0,
           z: z / 1.0,
           a: speed_x / 100 * (max_speed_x || 1),
           b: speed_y / 100 * (max_speed_y || 1),
           c: speed_z / 100 * (max_speed_z || 1)
         ] do
      result = FarmbotFirmware.command({nil, {:command_movement, params}})
      finish_movement(result)
    else
      error -> finish_movement(error)
    end
  end

  @estopped "Cannot execute commands while E-stopped"
  def finish_movement(:ok), do: :ok
  def finish_movement({:ok, _}), do: :ok
  def finish_movement({:error, reason}), do: finish_movement(reason)

  def finish_movement(:emergency_lock) do
    finish_movement(@estopped)
  end

  def finish_movement(err) when is_binary(err) do
    msg = "Movement failed. #{err}"
    FarmbotCore.Logger.error(1, msg)
    {:error, msg}
  end

  def finish_movement(reason) do
    msg = "Movement failed. #{inspect(reason)}"
    FarmbotCore.Logger.error(1, msg)
    {:error, msg}
  end

  def calibrate(axis) do
    axis = assert_axis!(axis)

    case FarmbotFirmware.command({:command_movement_calibrate, [axis]}) do
      :ok ->
        :ok

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("calibrate()", reason)
    end
  end

  def find_home(axis) do
    axis = assert_axis!(axis)

    case FarmbotFirmware.command({:command_movement_find_home, [axis]}) do
      :ok ->
        :ok

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("find_home", reason)
    end
  end

  def home(axis, _speed) do
    # TODO(Connor) fix speed
    axis = assert_axis!(axis)

    case FarmbotFirmware.command({:command_movement_home, [axis]}) do
      :ok ->
        :ok

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("home", reason)
    end
  end

  defp param_read(param) do
    case FarmbotFirmware.request({:parameter_read, [param]}) do
      {:ok, {_, {:report_parameter_value, [{^param, value}]}}} -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  defp assert_axis!(axis) when is_atom(axis),
    do: axis

  defp assert_axis!(axis) when axis in ~w(x y z),
    do: String.to_existing_atom(axis)

  defp assert_axis!(axis) do
    raise("unknown axis #{axis}")
  end
end
