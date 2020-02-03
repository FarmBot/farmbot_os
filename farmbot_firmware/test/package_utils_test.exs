defmodule FarmbotFirmware.PackageUtilsTest do
  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!
  alias FarmbotFirmware.PackageUtils

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

    assert {:error, "unknown firmware hardware: no"} ==
             PackageUtils.find_hex_file("no")
  end
end
