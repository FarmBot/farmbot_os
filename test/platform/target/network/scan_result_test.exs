defmodule Farmbot.Target.Network.ScanResultTest do
  use ExUnit.Case, async: false

  alias Farmbot.Target.Network.ScanResult

  describe "hi" do
    test "nice" do
      require IEx; IEx.pry
      result = ScanResult.decode(%{})
      assert result == nil
    end
  end
end
