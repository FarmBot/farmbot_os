defmodule FarmbotOS.SysCalls.SetPinIOMode do
  @moduledoc false
  alias FarmbotOS.Firmware.Command

  def set_pin_io_mode(pin_number, mode) do
    mode = extract_set_pin_mode(mode)

    case Command.set_pin_io_mode(pin_number, mode) do
      {:ok, _} ->
        :ok

      reason ->
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
