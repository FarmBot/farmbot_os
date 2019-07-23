defmodule FarmbotOS.SysCalls.FlashFirmware do
  alias FarmbotCore.{Asset, Asset.Private}
  alias FarmbotFirmware
  alias FarmbotCore.FirmwareTTYDetector
  require FarmbotCore.Logger
  require Logger

  def flash_firmware(package) do
    FarmbotCore.Logger.busy(2, "Starting firmware flash for package: #{package}")

    with {:ok, hex_file} <- find_hex_file(package),
         {:ok, tty} <- find_tty(),
         {:ok, fun} <- find_reset_fun(package),
         :ok <- FarmbotFirmware.close_transport(),
         {_, 0} <- Avrdude.flash(hex_file, tty, fun) do
      FarmbotCore.Logger.success(2, "Firmware flashed successfully!")

      %{
        # firmware_hardware: package, 
        firmware_path: tty
      }
      |> Asset.update_fbos_config!()
      |> Private.mark_dirty!(%{})

      :ok
    else
      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      {_, exit_code} when is_number(exit_code) ->
        {:error, "avrdude error: #{exit_code}"}
    end
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

  defp find_hex_file("arduino") do
    Application.app_dir(:farmbot_firmware, ["priv", "arduino_firmware.hex"]) |> assert_exists()
  end

  defp find_hex_file("farmduino") do
    Application.app_dir(:farmbot_firmware, ["priv", "farmduino.hex"]) |> assert_exists()
  end

  defp find_hex_file("farmduino_k14") do
    Application.app_dir(:farmbot_firmware, ["priv", "farmduino_k14.hex"]) |> assert_exists()
  end

  defp find_hex_file("express_k10") do
    Application.app_dir(:farmbot_firmware, ["priv", "express_k10.hex"]) |> assert_exists()
  end

  defp find_hex_file(hardware) when is_binary(hardware),
    do: {:error, "unknown firmware hardware: #{hardware}"}

  defp find_reset_fun(_) do
    config = Application.get_env(:farmbot_firmware, FarmbotFirmware.UARTTransport)

    if module = config[:reset] do
      {:ok, &module.reset/0}
    else
      {:ok, fn -> :ok end}
    end
  end

  defp assert_exists(fname) do
    if File.exists?(fname) do
      {:ok, fname}
    else
      {:error,
       """
       File does not exist: #{fname}
       The arduino firmware is a git submodule to the farmbot project.
       Please call `make arudino_firmware`.
       """}
    end
  end
end
