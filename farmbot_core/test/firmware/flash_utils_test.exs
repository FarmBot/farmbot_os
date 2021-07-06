defmodule FarmbotCore.Firmware.FlashUtilsTest do
  use ExUnit.Case
  alias FarmbotCore.Firmware.FlashUtils

  test "find_hex_file/1" do
    %{
      "arduino" => "/priv/arduino_firmware.hex",
      "farmduino" => "/priv/farmduino.hex",
      "farmduino_k14" => "/priv/farmduino_k14.hex",
      "farmduino_k15" => "/priv/farmduino_k15.hex",
      "farmduino_k16" => "/priv/farmduino_k16.hex",
      "express_k10" => "/priv/express_k10.hex",
      "none" => "/priv/eeprom_clear.ino.hex"
    }
    |> Enum.map(fn {fw, expected} ->
      {:ok, path} = FlashUtils.find_hex_file(fw)
      assert String.contains?(path, expected)
    end)
  end
end
