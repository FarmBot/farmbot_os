defmodule FarmbotOS.SysCalls.Movement do
  @moduledoc false

  require FarmbotOS.Logger
  alias FarmbotOS.Firmware.Command
  alias FarmbotOS.BotState

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
    case Command.set_zero(assert_axis!(axis)) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("zero()", reason)
    end
  end

  def get_position() do
    # Update read cache
    case Command.report_current_position() do
      {:ok, %{x: x, y: y, z: z}} -> [x: x, y: y, z: z]
      reason -> FarmbotOS.SysCalls.give_firmware_reason("get_position", reason)
    end
  end

  def get_position(axis) do
    case get_position() do
      {:error, _} = error -> error
      position -> Keyword.fetch!(position, assert_axis!(axis))
    end
  end

  def get_cached_position() do
    %{x: x, y: y, z: z} = BotState.fetch().location_data.position
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
    %{x: x, y: y, z: z, a: speed_x, b: speed_y, c: speed_z}
    |> Command.move_abs()
    |> finish_movement()
  end

  def finish_movement(:ok), do: :ok
  def finish_movement({:ok, _}), do: :ok
  def finish_movement({:error, reason}), do: finish_movement(reason)

  def finish_movement(nil),
    do: {:error, "Movement error. See logs for details."}

  def finish_movement(reason) do
    msg = "Movement failed. #{inspect(reason)}"
    FarmbotOS.Logger.error(1, msg)
    {:error, msg}
  end

  def calibrate(axis) do
    case Command.find_length(assert_axis!(axis)) do
      {:ok, _} ->
        :ok

      reason ->
        FarmbotOS.SysCalls.give_firmware_reason("calibrate()", reason)
    end
  end

  def find_home(axis) do
    case Command.find_home(assert_axis!(axis)) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("find_home", reason)
    end
  end

  def home(axis, _speed) do
    case Command.go_home(assert_axis!(axis)) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("home", reason)
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
