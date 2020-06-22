defmodule FarmbotOS.SysCalls.FlashFirmware do
  @moduledoc false

  alias FarmbotCore.{Asset, Asset.Private, FirmwareResetter}
  alias FarmbotFirmware
  alias FarmbotCore.FirmwareTTYDetector

  import FarmbotFirmware.PackageUtils,
    only: [find_hex_file: 1, package_to_string: 1]

  require FarmbotCore.Logger
  require Logger

  def flash_firmware(package) do
    FarmbotCore.Logger.busy(
      2,
      "Flashing #{package_to_string(package)} firmware"
    )

    with {:ok, hex_file} <- find_hex_file(package),
         {:ok, tty} <- find_tty(),
         _ <-
           FarmbotCore.Logger.debug(3, "found tty: #{tty} for firmware flash"),
         {:ok, fun} <- FirmwareResetter.find_reset_fun(package),
         _ <-
           FarmbotCore.Logger.debug(
             3,
             "Closing the firmware transport before flash"
           ),
         :ok <- FarmbotFirmware.close_transport(),
         _ <- FarmbotCore.Logger.debug(3, "starting firmware flash"),
         result <- Avrdude.flash(hex_file, tty, fun) do
      finish_flashing(result, tty)
      :ok
    else
      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      error ->
        {:error, "flash_firmware returned #{inspect(error)}"}
    end
  end

  def finish_flashing({_result, 0}, tty) do
    FarmbotCore.Logger.success(
      1,
      "Firmware flashed successfully. Unlock FarmBot to finish initialization."
    )

    %{firmware_path: tty}
    |> Asset.update_fbos_config!()
    |> Private.mark_dirty!(%{})
  end

  def finish_flashing(result, _) do
    FarmbotCore.Logger.debug(2, "AVR flash returned #{inspect(result)}")
  end

  def find_tty() do
    case FirmwareTTYDetector.tty() do
      nil ->
        {:error,
         """
         No suitable TTY detected. Check cables and try again.
         """}

      tty ->
        {:ok, tty}
    end
  end
end
