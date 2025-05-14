defmodule FarmbotOS.Firmware.UARTDetector do
  alias FarmbotOS.Firmware.UARTCoreSupport, as: Support
  alias FarmbotOS.Asset

  require FarmbotOS.Logger

  @failure "UNABLE TO SELECT FARMDUINO! Please connect farmduino or set a valid firmware path."
  @third_guess %{
    "arduino" => "ttyACM0",
    "express_k10" => "ttyAMA0",
    "express_k11" => "ttyUSB0",
    "express_k12" => "ttyUSB0",
    "farmduino_k14" => "ttyACM0",
    "farmduino_k15" => "ttyACM0",
    "farmduino_k16" => "ttyACM0",
    "farmduino_k17" => "ttyACM0",
    "farmduino_k18" => "ttyACM0",
    "farmduino" => "ttyACM0"
  }

  # Returns nil or a string path to the Farmduino.
  # Example: "ttyAMA0", "ttyUSB0", etc..
  def run do
    recent_boot = FarmbotOS.Firmware.UARTCoreSupport.recent_boot?()

    if recent_boot do
      uarts = inspect(uart_list())
      FarmbotOS.Logger.info(1, "Detecting available UARTs: #{uarts}")
    end

    conf = Asset.fbos_config()
    p = conf.firmware_path
    fwhw = conf.firmware_hardware
    path_or_nil = maybe_use_path(p) || second_guess() || third_guess(fwhw)

    if !path_or_nil && recent_boot do
      FarmbotOS.Logger.error(1, @failure)
    end

    {fwhw, path_or_nil}
  end

  defp maybe_use_path(path) do
    # Just because the user has a `firmware_path` doesn't
    # mean the device is plugged in- verify before
    # proceeding. Otherwise, try to guess.
    if path && Support.device_available?(path) do
      path
    end
  end

  # If the `firmware_path` is not set, we can still try to
  # guess. We only guess if there is _EXACTLY_ one serial
  # device. This is to prevent interference with DIY setups.
  defp second_guess() do
    case uart_list() do
      [uart] -> uart
      _ -> nil
    end
  end

  defp third_guess(firmware_hardware) do
    maybe_use_path(Map.get(@third_guess, firmware_hardware))
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
