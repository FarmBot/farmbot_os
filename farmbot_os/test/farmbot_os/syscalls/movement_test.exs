defmodule FarmbotOS.SysCalls.MovementTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.SysCalls.Movement

  test "get_current_(x|y|z)" do
    expect(FarmbotFirmware, :request, 3, fn _args ->
      fake_stuff = [x: 1, y: 2, z: 3]
      {:ok, {:whatever, {:report_position, fake_stuff}}}
    end)

    assert 1 == Movement.get_current_x()
    assert 2 == Movement.get_current_y()
    assert 3 == Movement.get_current_z()
  end

  test "get_cached_(x|y|z)" do
    expect(FarmbotCore.BotState, :fetch, 3, fn ->
      %FarmbotCore.BotStateNG{
        location_data: %{
          position: %{
            x: 1,
            y: 2,
            z: 3,
          }
        }
      }
    end)

    assert 1 == Movement.get_cached_x()
    assert 2 == Movement.get_cached_y()
    assert 3 == Movement.get_cached_z()
  end
end
