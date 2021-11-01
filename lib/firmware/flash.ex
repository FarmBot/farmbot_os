defmodule FarmbotOS.Firmware.Flash do
  alias FarmbotOS.Firmware.UARTCoreSupport

  alias FarmbotOS.Firmware.{
    Resetter,
    Avrdude
  }

  require FarmbotOS.Logger
  @reason "Starting firmware flash."
  @flash_ok "Success: Firmware flashed. MD5: "

  # Calls `raw_flash()`, plus makes additional calls to keep
  # UARTCore's state tree tidy.
  def run(state, package) do
    FarmbotOS.Logger.debug(3, @reason)
    {:ok, tty} = UARTCoreSupport.disconnect(state, @reason)
    raw_flash(package, tty)
    FarmbotOS.Firmware.UARTCore.restart_firmware()
    state
  end

  # This function resets the firmware, but makes no
  # reference to UARTCore.
  def raw_flash(package, tty) do
    FarmbotOS.BotState.set_firmware_hardware(package)
    {:ok, hex_file} = FarmbotOS.Firmware.FlashUtils.find_hex_file(package)
    {:ok, fun} = Resetter.find_reset_fun(package)
    result = Avrdude.flash(hex_file, tty, fun)
    finish_flashing(result, hex_file)
  end

  def finish_flashing({_, 0}, hex_file) do
    FarmbotOS.Logger.success(1, @flash_ok <> get_hash(hex_file))
  end

  def finish_flashing({string, _}, _) when is_binary(string) do
    missing_bootloader? =
      string |> String.downcase() |> String.contains?("unknown")

    if missing_bootloader? do
      FarmbotOS.Logger.error(
        2,
        "Flash failed: Farmduino may need new bootloader!"
      )

      FarmbotOS.Logger.error(2, inspect(string))
    else
      FarmbotOS.Logger.error(2, "Flash failed: #{inspect(string)}")
    end
  end

  def finish_flashing(result, _) do
    FarmbotOS.Logger.error(2, "Unexpected flash failure #{inspect(result)}")
  end

  def get_hash(file) do
    :crypto.hash(:md5, File.read!(file))
    |> Base.encode16()
    |> String.slice(0..10)
  end
end
