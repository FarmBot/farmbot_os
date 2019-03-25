defmodule FarmbotOS.SysCalls.FlashFirmware do
  alias FarmbotCore.{Asset, Asset.Private}
  alias FarmbotFirmware
  require Logger

  def flash_firmware(package) do
    hex_file = find_hex_file(package)

    tty =
      FarmbotOS.FirmwareTTYDetector.tty() ||
        raise """
        Expected a tty to exist, but none was found.
        """

    case Avrdude.flash(hex_file, tty) do
      {_, 0} ->
        %{firmware_hardware: package, firmware_path: tty}
        |> Asset.update_fbos_config!()
        |> Private.mark_dirty!(%{})

        Private.clear_enigma("firmware.missing")
        :ok

      _ ->
        {:error, "avrdude_failure"}
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

  defp assert_exists(fname) do
    if File.exists?(fname) do
      fname
    else
      raise """
      File does not exist: #{fname}
      The arduino firmware is a git submodule to the farmbot project.
      Please call `make arudino_firmware`.
      """
    end
  end
end
