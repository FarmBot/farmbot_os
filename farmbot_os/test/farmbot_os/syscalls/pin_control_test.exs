defmodule FarmbotOS.SysCalls.PinControlTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.SysCalls.PinControl

  test "read_cached_pin" do
    expect(FarmbotCore.BotState, :fetch, 1, fn ->
      %FarmbotCore.BotStateNG{ pins: %{ 4 => %{ value: 6 } } }
    end)
    assert 6 == PinControl.read_cached_pin(4)
  end
end
