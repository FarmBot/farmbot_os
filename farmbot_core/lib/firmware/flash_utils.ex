defmodule FarmbotFirmware.FlashUtils do
  @doc "Returns the absolute path to the hex file associated with `package`"
  def find_hex_file("arduino"), do: find("arduino_firmware.hex")
  def find_hex_file("farmduino"), do: find("farmduino.hex")
  def find_hex_file("farmduino_k14"), do: find("farmduino_k14.hex")
  def find_hex_file("farmduino_k15"), do: find("farmduino_k15.hex")
  def find_hex_file("express_k10"), do: find("express_k10.hex")
  def find_hex_file("none"), do: find("eeprom_clear.ino.hex")

  def find_hex_file(hardware) do
    {:error, "unknown firmware hardware: #{inspect(hardware)}"}
  end

  defp find(name) do
    assert_exists(Application.app_dir(:farmbot_core, ["priv", name]))
  end

  defp assert_exists(fname) do
    if File.exists?(fname) do
      {:ok, fname}
    else
      {:error, "Firmware hex file does not exist: #{fname}"}
    end
  end
end
