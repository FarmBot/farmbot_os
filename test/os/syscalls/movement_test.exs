defmodule FarmbotOS.SysCalls.MovementTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.SysCalls.Movement
  alias FarmbotOS.Firmware.Command

  test "home/1" do
    expect(Command, :go_home, 2, fn
      :x -> {:ok, nil}
      :y -> {:error, "error"}
    end)

    assert :ok == Movement.home(:x, 100)
    {:error, message} = Movement.home(:y, 100)
    assert "Firmware error @ \"home\": \"error\"" == message
  end

  test "find_home/1" do
    expect(Command, :find_home, 2, fn
      :x -> {:ok, nil}
      :y -> {:error, "whoops"}
    end)

    assert :ok == Movement.find_home(:x)
    {:error, message} = Movement.find_home(:y)
    assert "Firmware error @ \"find_home\": \"whoops\"" == message
  end

  test "calibrate/1" do
    expect(Command, :find_length, 2, fn
      :x -> {:ok, nil}
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
    expect(Command, :move_abs, 1, fn _ -> {:ok, nil} end)
    assert :ok == Movement.move_absolute(1, 2, 3, 4)
  end

  test "move_absolute/4 - unexpected error (not a tuple)" do
    msg = "kaboom"
    formatted_msg = "Movement failed. " <> inspect(msg)

    expect(Command, :move_abs, 1, fn _ -> msg end)

    expect(FarmbotOS.LogExecutor, :execute, 1, fn log ->
      assert log.message == formatted_msg
    end)

    {:error, error_log} = Movement.move_absolute(1, 2, 3, 4, 5, 6)
    assert formatted_msg == error_log
  end

  @tag :capture_log
  test "move_absolute/4 - error (in tuple)" do
    msg = "boom"
    formatted_msg = "Movement failed. " <> inspect(msg)

    expect(FarmbotOS.LogExecutor, :execute, 1, fn log ->
      assert log.message == formatted_msg
    end)

    expect(Command, :move_abs, 1, fn _ ->
      {:error, msg}
    end)

    {:error, error_log} = Movement.move_absolute(1, 2, 3, 4)
    assert formatted_msg == error_log
  end

  test "get_position/1 - error" do
    expect(Command, :report_current_position, 1, fn -> "boom" end)
    message = "Firmware error @ \"get_position\": \"boom\""
    assert {:error, ^message} = Movement.get_position(:x)
  end

  test "zero()" do
    expect(Command, :set_zero, 2, fn
      :y -> {:error, "my test"}
      :x -> {:ok, nil}
    end)

    expected = "Firmware error @ \"zero()\": \"my test\""
    assert {:error, ^expected} = Movement.zero(:y)
    assert :ok == Movement.zero("x")
  end

  test "get_current_(x|y|z)" do
    expect(Command, :report_current_position, 3, fn ->
      {:ok, %{x: 1, y: 2, z: 3}}
    end)

    assert 1 == Movement.get_current_x()
    assert 2 == Movement.get_current_y()
    assert 3 == Movement.get_current_z()
  end

  test "get_cached_(x|y|z)" do
    expect(FarmbotOS.BotState, :fetch, 3, fn ->
      %FarmbotOS.BotStateNG{
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
