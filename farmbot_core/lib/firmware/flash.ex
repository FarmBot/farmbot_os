defmodule FarmbotCore.Firmware.Flash do
  # @moduledoc false

  # alias FarmbotCore.{Asset, Asset.Private, FirmwareResetter}
  # alias FarmbotFirmware
  # alias FarmbotCore.FirmwareTTYDetector

  # require FarmbotCore.Logger
  # require Logger

  def run(_state, _package) do
    #   :ok = FarmbotFirmware.close_transport(),
    #   tty = state.uart_path
    #   {:ok, hex_file} = FarmbotFirmware.FlashUtils.find_hex_file(package)
    #   {:ok, fun} = FirmwareResetter.find_reset_fun(package),
    #   result = Avrdude.flash(hex_file, tty, fun) do
    #   finish_flashing(result, tty)
    #   state
    raise "WORK IN PROGRESS"
  end

  # def finish_flashing({_result, 0}, tty) do
  #   FarmbotCore.Logger.success(
  #     1,
  #     "Success: Firmware flashed. Unlock FarmBot to continue."
  #   )
  # end

  # def finish_flashing(result, _) do
  #   FarmbotCore.Logger.debug(2, "AVR flash returned #{inspect(result)}")
  # end
end
