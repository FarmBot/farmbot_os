defmodule FarmbotOS.Asset.BoxLedTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.BoxLed

  test "to_string" do
    assert "BoxLed 23" == to_string(%BoxLed{id: 23})
  end
end
