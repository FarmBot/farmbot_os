defmodule FarmbotOS.SysCalls.SetPinIOMode do
  @moduledoc false

  def set_pin_io_mode(pin_number, mode) do
    mode = extract_set_pin_mode(mode)

    case FarmbotCore.Firmware.command(
           {:pin_mode_write, [p: pin_number, m: mode]}
         ) do
      :ok ->
        :ok

      {:error, reason} ->
        FarmbotOS.SysCalls.give_firmware_reason("set_pin_io_mode", reason)
    end
  end

  def extract_set_pin_mode("input"), do: 0x0
  def extract_set_pin_mode("input_pullup"), do: 0x2
  def extract_set_pin_mode("output"), do: 0x1
  def extract_set_pin_mode(0x0), do: 0x0
  def extract_set_pin_mode(0x2), do: 0x2
  def extract_set_pin_mode(0x1), do: 0x1
end
