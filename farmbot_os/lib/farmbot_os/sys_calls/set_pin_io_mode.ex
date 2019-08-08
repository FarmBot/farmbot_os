defmodule FarmbotOS.SysCalls.SetPinIOMode do
  alias FarmbotFirmware

  def set_pin_io_mode(pin_number, mode) do
    mode = extract_set_pin_mode(to_string(mode))

    case FarmbotFirmware.command({:pin_mode_write, [p: pin_number, m: mode]}) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Firmware error: #{inspect(reason)}"}
    end
  end

  def extract_set_pin_mode("input"), do: 0x0
  def extract_set_pin_mode("input_pullup"), do: 0x2
  def extract_set_pin_mode("output"), do: 0x1
end
