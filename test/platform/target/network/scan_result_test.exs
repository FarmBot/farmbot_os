defmodule Farmbot.Target.Network.ScanResultTest do
  use ExUnit.Case, async: false

  alias Farmbot.Target.Network.ScanResult

  describe "decode/1" do
    test "returns a an empty struct when we pass in an empty map" do
      result = ScanResult.decode(%{})
      expected = %Farmbot.Target.Network.ScanResult{
                                                     bssid: nil,
                                                     capabilities: nil,
                                                     flags: nil,
                                                     level: nil,
                                                     noise: nil,
                                                     security: nil,
                                                     ssid: nil
                                                   }
      assert result == expected
      assert result.__struct__ == Farmbot.Target.Network.ScanResult
    end

    test "returns a list of structs when we pass in empty maps" do
      list_of_maps = [%{}, %{}]
      result = ScanResult.decode(list_of_maps)
      first_struct = Enum.at(result, 0)

      assert is_list(result) == true
      assert first_struct.__struct__ == Farmbot.Target.Network.ScanResult
      assert Enum.count(result) == Enum.count(list_of_maps)
    end
  end

  describe "sort_results/1" do
    test "returns a sorted list of ssids by their level" do
      "..."
    end
  end
end
