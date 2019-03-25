defmodule FarmbotOS.SysCalls.FlashFirmware do
  alias FarmbotCore.{Asset, Asset.Private}
  alias FarmbotFirmware
  alias FarmbotOS.FirmwareTTYDetector
  require Logger

  def flash_firmware(package) do
    with {:ok, hex_file} <- find_hex_file(package),
         {:ok, tty} <- find_tty(),
         {_, 0} <- Avrdude.flash(hex_file, tty) do
      %{firmware_hardware: package, firmware_path: tty}
      |> Asset.update_fbos_config!()
      |> Private.mark_dirty!(%{})

      :ok = Private.clear_enigma!("firmware.missing")
      :ok
    else
      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      {_, exit_code} when is_number(exit_code) ->
        {:error, "avrdude error: #{exit_code} see logs."}
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
    Application.app_dir(:farmbot_core, ["priv", "arduino_firmware.hex"]) |> assert_exists()
  end

  defp find_hex_file("farmduino") do
    Application.app_dir(:farmbot_core, ["priv", "farmduino.hex"]) |> assert_exists()
  end

  defp find_hex_file("farmduino_k14") do
    Application.app_dir(:farmbot_core, ["priv", "farmduino_k14.hex"]) |> assert_exists()
  end

  defp find_hex_file(hardware) when is_binary(hardware),
    do: {:error, "unknown firmware hardware: #{hardware}"}

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
