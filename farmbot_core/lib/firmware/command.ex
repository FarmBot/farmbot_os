defmodule FarmbotCore.Firmware.Command do
  alias FarmbotFirmware.Parameter
  alias FarmbotCore.Firmware.UARTCore

  # E   Emergency stop
  def lock(), do: UARTCore.send_raw("E")

  # F09 Reset emergency stop
  def unlock(), do: UARTCore.send_raw("F09")

  # G28 Move home all axis (Z, Y, X axis order)
  def go_home(), do: schedule("G28")

  # F11 Home X axis (find 0, 3 attempts) *
  def find_home(:x), do: schedule("F11")

  # F12 Home Y axis (find 0, 3 attempts) *
  def find_home(:y), do: schedule("F12")

  # F13 Home Z axis (find 0, 3 attempts) *
  def find_home(:z), do: schedule("F13")

  # F14 Calibrate X axis (measure length + find 0) *
  def calibrate(:x), do: schedule("F14")

  # F15 Calibrate Y axis (measure length + find 0) *
  def calibrate(:y), do: schedule("F15")

  # F16 Calibrate Z axis (measure length + find 0) *
  def calibrate(:z), do: schedule("F16")

  # F20 List all parameters and value
  def read_params(), do: schedule("F20")

  # # F21(P) Read parameter
  def read_param(param), do: schedule("F21 #{encode_p(param)}")

  # F22(P, V) Write parameter
  def write_param(param, val) do
    gcode = "F22 #{encode_p(param)} V#{encode_float(val)}"
    schedule(gcode)
  end

  # F81 Report end stop
  def report_end_stops(), do: schedule("F81")

  # F82
  def report_current_position(), do: schedule("F82")

  # F83
  def report_software_version(), do: schedule("F83")

  # ==== TODO:
  # F41(P, V, M) Set a value V on an arduino pin in mode M (digital=0/analog=1)
  # F84(X, Y, Z) Set axis current position to zero (yes=1/no=0)
  # F61(P, V) Set the servo on the pin P (only pins 4, 5, 6, and 11) to the requested angle V
  # F42(P, M) Read a value from an arduino pin P in mode M (digital=0/analog=1)
  # F43(P, M) Set the I/O mode M (input=0/output=1) of a pin P in arduino
  # G00(X, Y, Z, A, B, C) Move to location at given speed for axis in absolute coordinates
  # ==== TODO ^

  # === Not implemented??:
  # F44(P, V, W T M) Set the value V on an arduino pin P,
  # wait for time T in milliseconds, set value W on the
  # arduino pin P in mode M (digital=0/analog=1)
  def toggle_pin_maybe?() do
    raise "Not used??"
  end

  # F23(P, V) Update parameter (during calibration)
  def update_param(param, val) do
    gcode = "F22 #{encode_p(param)} V#{encode_float(val)}"
    schedule(gcode)
  end

  def f22({param, val}), do: "F22 #{encode_p(param)} V#{encode_float(val)}"

  defp schedule(gcode), do: UARTCore.start_job(gcode)

  defp encode_float(v), do: :erlang.float_to_binary(v, decimals: 2)

  defp encode_p(p) when is_number(p) do
    # Crash on bad input:
    _ = Parameter.translate(p)
    # String.pad_leading(, 3, ["0"])
    "P#{p}"
  end

  defp encode_p(p) do
    number = Parameter.translate(p)

    if is_integer(number) do
      encode_p(number)
    else
      raise "Bad parameter value: #{inspect(p)}"
    end
  end
end
