defmodule FarmbotCore.Asset.BoxLedTest do
  use ExUnit.Case, async: false
  alias FarmbotCore.Asset.BoxLed

  test "to_string" do
    assert "BoxLed 23" == to_string(%BoxLed{id: 23})
  end
end
