defmodule FarmbotOS.SysCalls.FlashFirmware do
  alias FarmbotFirmware

  def flash_firmware(package) do
    FarmbotCore.Asset.Private.clear_enigma("firmware.missing")
    hex_file = find_hex_file(package)
    tty = find_tty()
    Avrdude.flash_firmware(hex_file, "?")
    raise package
  end

  defp find_tty() do
    File.ls("/dev/ttylol*")
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
