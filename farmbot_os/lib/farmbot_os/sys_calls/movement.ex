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
    do_move_absolute(x, y, z, speed)
  end

  defp do_move_absolute(x, y, z, speed) do
    with {:ok, speed_x} <- param_read(:movement_max_spd_x),
         {:ok, speed_y} <- param_read(:movement_max_spd_y),
         {:ok, speed_z} <- param_read(:movement_max_spd_z),
         params <- [
           x: x / 1.0,
           y: y / 1.0,
           z: z / 1.0,
           a: speed / 100 * (speed_x || 1),
           b: speed / 100 * (speed_y || 1),
           c: speed / 100 * (speed_z || 1)
         ],
         :ok <- FarmbotFirmware.command({nil, {:command_movement, params}}) do
      :ok
    else
      {:error, :emergency_lock} ->
        {:error, "emergency_lock"}

      {:error, reason} ->
        handle_movement_error(reason)

      reason ->
        handle_movement_error(reason)
    end
  end

  def handle_movement_error(reason) do
    msg = "Movement failed. #{inspect(reason)}"
    FarmbotCore.Logger.error(1, msg)
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
