defmodule FarmbotCore.Firmware.Command do
  alias FarmbotFirmware.Parameter
  alias FarmbotCore.Firmware.{UARTCore, FloatingPoint}
  alias FarmbotCore.BotState

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

  # E   Emergency stop
  def lock(), do: UARTCore.send_raw("E")

  # F09 Reset emergency stop
  def unlock(), do: UARTCore.send_raw("F09")

  # G28 Move home all axis (Z, Y, X axis order)
  def go_home(), do: schedule(:G28, [])
  # Firmware has a bug where trying to go home on a single
  # axis fails. We can get around this limitation by faking
  # it with G00
  def go_home("x"), do: set_zero(:x)
  def go_home("y"), do: set_zero(:y)
  def go_home("z"), do: set_zero(:z)

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

  # F20 List all parameters and value
  def read_params(), do: schedule(:F20, [])

  # # F21(P) Read parameter
  def read_param(param), do: schedule(:F21, P: param)

  # F22(P, V) Write parameter
  def write_param(param, val), do: schedule(:F22, P: param, V: val)

  # F81 Report end stop
  def report_end_stops(), do: schedule(:F81, [])

  # F82
  def report_current_position() do
    schedule(:F82, [])
    pos = %{x: _, y: _, z: _} = cached_position()
    {:ok, pos}
  end

  # F83
  def report_software_version(), do: schedule(:F83, [])

  @m_codes %{
    0 => 0,
    :input => 0,
    "input" => 0,
    "digital" => 0,
    :digital => 0,
    1 => 1,
    "output" => 1,
    :output => 1,
    "analog" => 1,
    :analog => 1,
    2 => 2,
    :input_pullup => 2,
    "input_pullup" => 2
  }

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
    {:ok, round(Map.fetch!(BotState.fetch().pins, pin).value)}
  end

  defp write_pm(f_code, pin, mode) do
    schedule("F#{inspect(f_code)}", P: pin, M: mode)
  end

  # F61(P, V) Set the servo on the pin P (only pins 4, 5, 6, and 11) to the requested angle V
  def move_servo(pin, angle) do
    schedule(:F61, P: pin, V: angle)
  end

  # F84(X, Y, Z) Set axis current position to zero (yes=1/no=0)
  def set_zero(:x), do: set_zero("x")
  def set_zero(:y), do: set_zero("y")
  def set_zero(:z), do: set_zero("z")

  def set_zero(axis) do
    yes = 1
    no = 0
    defaults = %{"x" => no, "y" => no, "z" => no}

    params =
      %{defaults | axis => yes}
      |> Map.to_list()
      |> Enum.map(fn {axis, value} ->
        "#{String.upcase(axis)}#{inspect(value)}"
      end)
      |> Enum.join(" ")

    schedule(:F84, params)
  end

  # === Not implemented??:
  # F44(P, V, W T M) Set the value V on an arduino pin P,
  # wait for time T in milliseconds, set value W on the
  # arduino pin P in mode M (digital=0/analog=1)
  def toggle_pin_maybe?() do
    raise "Not used??"
  end

  # F23(P, V) Update parameter (during calibration)
  def update_param(param, val) do
    schedule(:F22, P: param, V: val)
  end

  def f22({param, val}), do: "F22 #{encode_param(param)} V#{encode_float(val)}"

  defp schedule(command, parameters) when is_binary(parameters) do
    UARTCore.start_job("#{command} #{parameters}")
  end

  defp schedule(command, parameters) do
    mapper = fn
      {:M, mode} -> "M#{fetch_m!(mode)}"
      {key, value} -> "#{key}#{FloatingPoint.encode(value)}"
    end

    p =
      parameters
      |> Enum.map(mapper)
      |> Enum.join(" ")

    gcode = "#{command} #{p}"
    UARTCore.start_job(gcode)
  end

  defp encode_float(v), do: :erlang.float_to_binary(v, decimals: 2)

  defp encode_param(p) when is_number(p) do
    # Crash on bad input:
    _ = Parameter.translate(p)
    "P#{p}"
  end

  defp encode_param(p) do
    number = Parameter.translate(p)

    if is_integer(number) do
      encode_param(number)
    else
      raise "Bad parameter value: #{inspect(p)}"
    end
  end

  @temp_fallback %{
    movement_max_spd_x: 800.0,
    movement_max_spd_y: 800.0,
    movement_max_spd_z: 1000.0
  }

  defp max_speeds() do
    conf = FarmbotCore.Asset.firmware_config() || @temp_fallback

    {
      Map.fetch!(conf, :movement_max_spd_x) || 800.0,
      Map.fetch!(conf, :movement_max_spd_y) || 800.0,
      Map.fetch!(conf, :movement_max_spd_z) || 1000.0
    }
  end

  defp location() do
    if missing_cache?() do
      {:ok, pos} = report_current_position()
      pos
    else
      cached_position()
    end
  end

  defp missing_cache?(), do: Enum.member?(Map.values(cached_position()), nil)
  defp cached_position(), do: BotState.fetch().location_data.position

  defp fetch_m!(mode) do
    m = Map.get(@m_codes, mode)

    if m do
      FloatingPoint.encode(m)
    else
      valid_modes =
        @m_codes
        |> Map.keys()
        |> Enum.filter(&is_atom/1)
        |> Enum.sort()

      raise "Expect pin mode to be one of #{valid_modes}. Got: #{inspect(mode)}"
    end
  end
end
