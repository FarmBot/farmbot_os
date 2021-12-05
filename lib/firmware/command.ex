defmodule FarmbotOS.Firmware.Command do
  alias FarmbotOS.BotState
  alias FarmbotOS.Firmware.{GCode, UARTCore}

  # G00(X, Y, Z, A, B, C) Move to location at given speed
  # for axis in absolute coordinates
  def move_abs(%{x: x, y: y, z: z, a: a, b: b, c: c}) do
    {max_speed_x, max_speed_y, max_speed_z} = max_speeds()

    opts = [
      X: x,
      Y: y,
      Z: z,
      A: a / 100.0 * max_speed_x,
      B: b / 100.0 * max_speed_y,
      C: c / 100.0 * max_speed_z
    ]

    schedule(:G00, opts)
  end

  # @ - @bort movement
  def abort(), do: UARTCore.send_raw("@")

  # E - Emergency stop
  def lock(), do: UARTCore.send_raw("E")

  # F09 Reset emergency stop
  def unlock(), do: UARTCore.send_raw("F09")

  # G28 Move home all axis (Z, Y, X axis order)
  def go_home(), do: schedule(:G28, [])
  # Firmware has a bug where trying to go home on a single
  # axis fails. We can get around this limitation by faking
  # it with G00
  def go_home("x"), do: go_home(:x)
  def go_home("y"), do: go_home(:y)
  def go_home("z"), do: go_home(:z)

  def go_home(axis) do
    %{x: x, y: y, z: z} = location()
    defaults = %{x: x, y: y, z: z, a: 100.0, b: 100.0, c: 100.0}
    move_abs(%{defaults | axis => 0.0})
  end

  # F11 Home X axis (find 0, 3 attempts) *
  def find_home(:x), do: schedule(:F11, [])

  # F12 Home Y axis (find 0, 3 attempts) *
  def find_home(:y), do: schedule(:F12, [])

  # F13 Home Z axis (find 0, 3 attempts) *
  def find_home(:z), do: schedule(:F13, [])

  # F14 Find length of X axis (measure length + find 0) *
  def find_length(:x), do: schedule(:F14, [])

  # F15 Find length of Y axis (measure length + find 0) *
  def find_length(:y), do: schedule(:F15, [])

  # F16 Find length of Z axis (measure length + find 0) *
  def find_length(:z), do: schedule(:F16, [])

  # F82
  def report_current_position() do
    schedule(:F82, [])
    pos = %{x: _, y: _, z: _} = cached_position()
    {:ok, pos}
  end

  def watch_pin(pin_number), do: schedule(:F22, P: 199, V: pin_number)

  # F43(P, M) Set the I/O mode M (input=0/output=1) of a pin P in arduino
  def set_pin_io_mode(pin, mode) do
    write_pm(43, pin, mode)
  end

  # F41(P, V, M) Set a value V on an arduino pin in mode M (digital=0/analog=1)
  def write_pin(pin, value, mode) do
    schedule(:F41, P: pin, V: value, M: mode)
  end

  # F42(P, M) Read a value from an arduino pin P in mode M (digital=0/analog=1)
  def read_pin(pin, mode) do
    {:ok, _} = write_pm(42, pin, mode)
    pins = BotState.fetch().pins
    key = trunc(pin)
    value = Map.fetch!(pins, key).value
    {:ok, round(value)}
  end

  defp write_pm(f_code, pin, mode) do
    schedule("F#{inspect(f_code)}", P: pin, M: mode)
  end

  # F61(P, V) Set the servo on the pin P (only pins 4, 5, 6, and 11) to the requested angle V
  def move_servo(pin, angle) do
    schedule(:F61, P: pin, V: angle)
  end

  # F84(X, Y, Z) Set axis current position to zero (yes=1/no=0)
  def set_zero(:x), do: set_zero(:X)
  def set_zero(:y), do: set_zero(:Y)
  def set_zero(:z), do: set_zero(:Z)

  def set_zero(axis) do
    yes = 1
    no = 0

    params =
      %{X: no, Y: no, Z: no}
      |> Map.put(axis, yes)
      |> Map.to_list()

    schedule(:F84, params)
  end

  defp schedule(command, parameters) do
    UARTCore.start_job(GCode.new(command, parameters))
  end

  @temp_fallback %{
    movement_max_spd_x: 800.0,
    movement_max_spd_y: 800.0,
    movement_max_spd_z: 1000.0
  }

  defp max_speeds() do
    conf = FarmbotOS.Asset.firmware_config() || @temp_fallback

    {
      Map.fetch!(conf, :movement_max_spd_x) || 800.0,
      Map.fetch!(conf, :movement_max_spd_y) || 800.0,
      Map.fetch!(conf, :movement_max_spd_z) || 1000.0
    }
  end

  defp location() do
    pos = cached_position()

    if Enum.member?(Map.values(pos), nil) do
      {:ok, pos} = report_current_position()
      pos
    else
      pos
    end
  end

  defp cached_position(), do: BotState.fetch().location_data.position
end
