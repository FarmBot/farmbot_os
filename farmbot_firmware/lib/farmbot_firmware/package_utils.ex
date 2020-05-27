defmodule FarmbotFirmware.PackageUtils do
  @doc "Returns the absolute path to the hex file associated with `package`"
  def find_hex_file(package)

  def find_hex_file("arduino") do
    Application.app_dir(:farmbot_firmware, ["priv", "arduino_firmware.hex"])
    |> assert_exists()
  end

  def find_hex_file("farmduino") do
    Application.app_dir(:farmbot_firmware, ["priv", "farmduino.hex"])
    |> assert_exists()
  end

  def find_hex_file("farmduino_k14") do
    Application.app_dir(:farmbot_firmware, ["priv", "farmduino_k14.hex"])
    |> assert_exists()
  end

  def find_hex_file("farmduino_k15") do
    Application.app_dir(:farmbot_firmware, ["priv", "farmduino_k15.hex"])
    |> assert_exists()
  end

  def find_hex_file("express_k10") do
    Application.app_dir(:farmbot_firmware, ["priv", "express_k10.hex"])
    |> assert_exists()
  end

  def find_hex_file("none") do
    Application.app_dir(:farmbot_firmware, ["priv", "eeprom_clear.ino.hex"])
    |> assert_exists()
  end

  def find_hex_file(hardware) when is_binary(hardware),
    do: {:error, "unknown firmware hardware: #{hardware}"}

  def find_hex_file(hardware)

  @doc "Returns the human readable string describing `package`"
  def package_to_string(package)

  def package_to_string("arduino"),
    do: "Arduino/RAMPS (Genesis v1.2)"

  def package_to_string("farmduino"),
    do: "Farmduino (Genesis v1.3)"

  def package_to_string("farmduino_k14"),
    do: "Farmduino (Genesis v1.4)"

  def package_to_string("farmduino_k15"),
    do: "Farmduino (Genesis v1.5)"

  def package_to_string("express_k10"),
    do: "Farmduino (Express v1.0)"

  def package_to_string(package),
    do: package

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
