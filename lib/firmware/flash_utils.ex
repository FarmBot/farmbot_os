defmodule FarmbotOS.Firmware.FlashUtils do
  require FarmbotOS.Logger

  @doc "Returns the absolute path to the hex file associated with `package`"
  def find_hex_file("arduino"), do: find("arduino_firmware.hex")
  def find_hex_file("express_k10"), do: find("express_k10.hex")
  def find_hex_file("express_k11"), do: find("express_k11.hex")
  def find_hex_file("express_k12"), do: find("express_k12.hex")
  def find_hex_file("farmduino_k14"), do: find("farmduino_k14.hex")
  def find_hex_file("farmduino_k15"), do: find("farmduino_k15.hex")
  def find_hex_file("farmduino_k16"), do: find("farmduino_k16.hex")
  def find_hex_file("farmduino_k17"), do: find("farmduino_k17.hex")
  def find_hex_file("farmduino_k18"), do: find("farmduino_k18.hex")
  def find_hex_file("farmduino"), do: find("farmduino.hex")
  def find_hex_file("none"), do: find("eeprom_clear.ino.hex")

  def find_hex_file(hardware) do
    {:error, "unknown firmware hardware: #{inspect(hardware)}"}
  end

  @custom_firmware "/boot/custom.hex"
  @scary_warning "Using `custom.hex` firmware file. I hope you know what you are doing..."

  defp find(name) do
    if File.exists?(@custom_firmware) do
      FarmbotOS.Logger.warn(3, @scary_warning)
      {:ok, @custom_firmware}
    else
      assert_exists(Application.app_dir(:farmbot, ["priv", "firmware", name]))
    end
  end

  defp assert_exists(fname) do
    if File.exists?(fname) do
      {:ok, fname}
    else
      {:error, "Firmware hex file does not exist: #{fname}"}
    end
  end
end
