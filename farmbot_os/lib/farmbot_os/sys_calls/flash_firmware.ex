defmodule FarmbotOS.SysCalls.FlashFirmware do
  @moduledoc false

  alias FarmbotCore.{Asset, Asset.Private}
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
         {:ok, fun} <- find_reset_fun(package),
         _ <-
           FarmbotCore.Logger.debug(
             3,
             "closing firmware transport before flash"
           ),
         :ok <- FarmbotFirmware.close_transport(),
         _ <- FarmbotCore.Logger.debug(3, "starting firmware flash"),
         _ <- finish_flashing(Avrdude.flash(hex_file, tty, fun)) do
      %{firmware_path: tty}
      |> Asset.update_fbos_config!()
      |> Private.mark_dirty!(%{})

      :ok
    else
      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      error ->
        {:error, "flash_firmware returned #{inspect(error)}"}
    end
  end

  def finish_flashing({_result, 0}) do
    FarmbotCore.Logger.success(2, "Firmware flashed successfully!")
  end

  def finish_flashing(result) do
    FarmbotCore.Logger.debug(2, "AVR Unexpected return code #{inspect(result)}")
  end

  defp find_tty() do
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

  defp find_reset_fun("express_k10") do
    FarmbotCore.Logger.debug(3, "Using special reset function for express")
    # "magic" workaround to avoid compiler warnings.
    # We used to inject this via App config, but it was
    # error prone.
    mod = :"Elixir.FarmbotOS.Platform.Target.FirmwareReset.GPIO"
    fun = &mod.reset/0
    {:ok, fun}
  end

  defp find_reset_fun(_) do
    FarmbotCore.Logger.debug(3, "Using default reset function")
    fun = &FarmbotFirmware.NullReset.reset/0
    {:ok, fun}
  end
end
