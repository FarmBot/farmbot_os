defmodule FarmbotOS.SysCalls.MovementTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.SysCalls.Movement
  alias FarmbotCore.Firmware.Command

  test "home/1" do
    expect(FarmbotCore.Firmware, :command, 2, fn
      {:command_movement_home, [:x]} -> :ok
      {:command_movement_home, [:y]} -> {:error, "error"}
    end)

    assert :ok == Movement.home(:x, 100)
    {:error, message} = Movement.home(:y, 100)
    assert "Firmware error @ \"home\": \"error\"" == message
  end

  test "find_home/1" do
    expect(FarmbotCore.Firmware, :command, 2, fn
      {:command_movement_find_home, [:x]} -> :ok
      {:command_movement_find_home, [:y]} -> {:error, "whoops"}
    end)

    assert :ok == Movement.find_home(:x)
    {:error, message} = Movement.find_home(:y)
    assert "Firmware error @ \"find_home\": \"whoops\"" == message
  end

  test "calibrate/1" do
    expect(Command, :find_length, 2, fn
      :x -> :ok
      :y -> {:error, "nope"}
    end)

    assert :ok == Movement.calibrate(:x)
    {:error, message} = Movement.calibrate(:y)
    assert "Firmware error @ \"calibrate()\": {:error, \"nope\"}" == message
  end

  test "catching bad axis values" do
    boom = fn -> Movement.find_home("q") end
    assert_raise RuntimeError, "unknown axis q", boom
  end

  test "move_absolute/4" do
    FarmbotCore.Firmware
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

  test "move_absolute/4 - unexpected error (not a tuple)" do
    FarmbotCore.Firmware
    |> expect(:request, 3, fn
      {:parameter_read, [:movement_max_spd_x]} ->
        {:ok, {:tag, {:report_parameter_value, [{:movement_max_spd_x, 1}]}}}

      {:parameter_read, [:movement_max_spd_y]} ->
        {:ok, {:tag, {:report_parameter_value, [{:movement_max_spd_y, 2}]}}}

      {:parameter_read, [:movement_max_spd_z]} ->
        {:ok, {:tag, {:report_parameter_value, [{:movement_max_spd_z, 3}]}}}
    end)
    |> expect(:command, 1, fn {nil, {:command_movement, _}} ->
      "kaboom"
    end)

    msg = "Movement failed. kaboom"

    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
      assert log.message == msg
    end)

    {:error, error_log} = Movement.move_absolute(1, 2, 3, 4)

    assert msg == error_log
  end

  @tag :capture_log
  test "move_absolute/4 - error (in tuple)" do
    expect(FarmbotCore.Firmware, :request, 1, fn {:parameter_read, [_]} ->
      {:error, "boom"}
    end)

    msg = "Movement failed. boom"

    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
      assert log.message == msg
    end)

    {:error, error_log} = Movement.move_absolute(1, 2, 3, 4)

    assert msg == error_log
  end

  test "get_position/1 - error" do
    expect(FarmbotCore.Firmware, :request, 1, fn {nil, {:position_read, []}} ->
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

    expect(FarmbotCore.Firmware, :command, 2, mock)

    expected = "Firmware error @ \"zero()\": \"my test\""
    assert {:error, ^expected} = Movement.zero(:y)
    assert :ok == Movement.zero("x")
  end

  test "get_current_(x|y|z)" do
    expect(FarmbotCore.Firmware, :request, 3, fn _args ->
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
