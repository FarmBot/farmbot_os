defmodule FarmbotOS.SysCalls.MovementTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.SysCalls.Movement

  test "move_absolute/4" do
    FarmbotFirmware
    |> expect(:request, 3, fn
      {:parameter_read, [:movement_max_spd_x]} ->
        {:ok, {:tag, {:report_parameter_value, [{:movement_max_spd_x, 1}]}}}

      {:parameter_read, [:movement_max_spd_y]} ->
        {:ok, {:tag, {:report_parameter_value, [{:movement_max_spd_y, 2}]}}}

      {:parameter_read, [:movement_max_spd_z]} ->
        {:ok, {:tag, {:report_parameter_value, [{:movement_max_spd_z, 3}]}}}
    end)
    |> expect(:command, 1, fn {nil, {:command_movement, params}} ->
      expected = [x: 1.0, y: 2.0, z: 3.0, a: 0.04, b: 0.08, c: 0.12]
      assert expected == params
      :ok
    end)

    result = Movement.move_absolute(1, 2, 3, 4)
    assert :ok == result
  end

  test "move_absolute/4 - error (in tuple)" do
    expect(FarmbotFirmware, :request, 1, fn {:parameter_read, [_]} ->
      {:error, "boom"}
    end)

    message = "Movement failed. \"boom\""

    assert message == Movement.move_absolute(1, 2, 3, 4).message
  end

  test "get_position/1 - error" do
    expect(FarmbotFirmware, :request, 1, fn {nil, {:position_read, []}} ->
      {:error, "boom"}
    end)

    message = "Firmware error @ \"get_position\": \"boom\""
    assert {:error, ^message} = Movement.get_position(:x)
  end

  test "zero()" do
    mock = fn
      {:position_write_zero, [:x]} ->
        :ok

      {:position_write_zero, [:y]} ->
        {:error, "my test"}
    end

    expect(FarmbotFirmware, :command, 2, mock)

    expected = "Firmware error @ \"zero()\": \"my test\""
    assert {:error, ^expected} = Movement.zero(:y)
    assert :ok == Movement.zero("x")
  end

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
            z: 3
          }
        }
      }
    end)

    assert 1 == Movement.get_cached_x()
    assert 2 == Movement.get_cached_y()
    assert 3 == Movement.get_cached_z()
  end
end
