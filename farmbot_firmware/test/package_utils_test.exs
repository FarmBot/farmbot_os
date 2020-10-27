defmodule FarmbotFirmware.PackageUtilsTest do
  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!
  alias FarmbotFirmware.PackageUtils

  test "package to string" do
    assert PackageUtils.package_to_string("arduino") ==
             "Arduino/RAMPS (Genesis v1.2)"

    assert PackageUtils.package_to_string("farmduino") ==
             "Farmduino (Genesis v1.3)"

    assert PackageUtils.package_to_string("farmduino_k14") ==
             "Farmduino (Genesis v1.4)"

    assert PackageUtils.package_to_string("farmduino_k15") ==
             "Farmduino (Genesis v1.5)"

    assert PackageUtils.package_to_string("express_k10") ==
             "Farmduino (Express v1.0)"

    assert PackageUtils.package_to_string("misc") == "misc"
  end

  test "not finding files" do
    expect(File, :exists?, 1, fn _fname ->
      false
    end)

    {:error, error} = PackageUtils.find_hex_file("arduino")
    assert String.contains?(error, "Please call `make arudino_firmware`.")
  end

  test "finding files" do
    {:ok, path} = PackageUtils.find_hex_file("arduino")
    assert String.contains?(path, "/farmbot_firmware/priv/arduino_firmware.hex")

    {:ok, path} = PackageUtils.find_hex_file("farmduino")
    assert String.contains?(path, "/farmbot_firmware/priv/farmduino.hex")

    {:ok, path} = PackageUtils.find_hex_file("farmduino_k14")
    assert String.contains?(path, "/farmbot_firmware/priv/farmduino_k14.hex")

    {:ok, path} = PackageUtils.find_hex_file("farmduino_k15")
    assert String.contains?(path, "/farmbot_firmware/priv/farmduino_k15.hex")

    {:ok, path} = PackageUtils.find_hex_file("express_k10")
    assert String.contains?(path, "/farmbot_firmware/priv/express_k10.hex")

    {:ok, path} = PackageUtils.find_hex_file("none")
    assert path =~ "lib/farmbot_firmware/priv/eeprom_clear.ino.hex"

    assert {:error, "unknown firmware hardware: \"no\""} ==
             PackageUtils.find_hex_file("no")
  end
end
