defmodule FarmbotOS.Firmware.FlashUtilsTest do
  use ExUnit.Case
  alias FarmbotOS.Firmware.FlashUtils

  test "find_hex_file/1" do
    %{
      "arduino" => "/priv/firmware/arduino_firmware.hex",
      "farmduino" => "/priv/firmware/farmduino.hex",
      "farmduino_k14" => "/priv/firmware/farmduino_k14.hex",
      "farmduino_k15" => "/priv/firmware/farmduino_k15.hex",
      "farmduino_k16" => "/priv/firmware/farmduino_k16.hex",
      "express_k10" => "/priv/firmware/express_k10.hex",
      "none" => "/priv/firmware/eeprom_clear.ino.hex"
    }
    |> Enum.map(fn {fw, expected} ->
      {:ok, path} = FlashUtils.find_hex_file(fw)
      assert String.contains?(path, expected)
    end)
  end
end
