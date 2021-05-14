defmodule FarmbotCore.Firmware.UARTDetector do
  alias FarmbotCore.Firmware.UARTCoreSupport, as: Support
  alias FarmbotCore.Asset

  # Returns nil or a string path to the Farmduino.
  # Example: "ttyAMA0", "ttyUSB0", etc..
  def run do
    conf = Asset.fbos_config()
    path_or_nil = guess_uart(conf.firmware_path)
    {conf.firmware_hardware, path_or_nil}
  end

  # If the `firmware_path` is not set, we can still try to
  # guess. We only guess if there is _EXACTLY_ one serial
  # device. This is to prevent interference with DIY setups.
  defp guess_uart(nil) do
    case uart_list() do
      [default_uart] -> default_uart
      _ -> nil
    end
  end

  defp guess_uart(path) do
    # Just because the user has a `firmware_path` doesn't
    # mean the device is plugged in- verify before
    # proceeding. Otherwise, try to guess.
    if Support.device_available?(path) do
      path
    else
      guess_uart(nil)
    end
  end

  defp uart_list() do
    Support.enumerate()
    |> Map.keys()
    |> Enum.filter(&filter_uart/1)
  end

  # GOAL: Filter out ttyS0 and friends.
  defp filter_uart("ttyACM" <> _), do: true
  defp filter_uart("ttyAMA" <> _), do: true
  defp filter_uart("ttyUSB" <> _), do: true
  defp filter_uart(_), do: false
end
