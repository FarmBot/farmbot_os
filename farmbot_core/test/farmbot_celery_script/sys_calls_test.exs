defmodule FarmbotCore.Celery.SysCallsTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotCore.Celery.{
    SysCalls,
    SysCalls.Stubs,
    AST
  }

  setup :verify_on_exit!

  test "point, OK" do
    expect(Stubs, :point, 1, fn _kind, 1 ->
      %{x: 100, y: 200, z: 300}
    end)

    result1 = SysCalls.point(Stubs, "Peripheral", 1)
    assert %{x: 100, y: 200, z: 300} == result1
  end

  test "point, NO" do
    expect(Stubs, :point, 1, fn _kind, 0 ->
      :whatever
    end)

    boom = fn -> SysCalls.point(Stubs, "Peripheral", 0) end
    assert_raise FarmbotCore.Celery.RuntimeError, boom
  end

  test "point groups failure" do
    expect(Stubs, :find_points_via_group, 1, fn _id ->
      :whatever
    end)

    boom = fn -> SysCalls.find_points_via_group(Stubs, :something_else) end
    assert_raise FarmbotCore.Celery.RuntimeError, boom
  end

  test "point groups success" do
    expect(Stubs, :find_points_via_group, 1, fn _id ->
      %{point_ids: [1, 2, 3]}
    end)

    pg = %{point_ids: [1, 2, 3]}
    result = SysCalls.find_points_via_group(Stubs, 456)
    assert result == pg
  end

  test "move_absolute, OK" do
    expect(Stubs, :move_absolute, 1, fn 1, 2, 3, 4 ->
      :ok
    end)

    assert :ok = SysCalls.move_absolute(Stubs, 1, 2, 3, 4)
  end

  test "move_absolute, NO" do
    expect(Stubs, :move_absolute, 1, fn 1, 2, 3, 4 ->
      {:error, "move failed!"}
    end)

    assert {:error, "move failed!"} ==
             SysCalls.move_absolute(Stubs, 1, 2, 3, 4)
  end

  test "get positions, OK" do
    expect(Stubs, :get_current_x, 1, fn -> 100.00 end)
    expect(Stubs, :get_current_y, 1, fn -> 200.00 end)
    expect(Stubs, :get_current_z, 1, fn -> 300.00 end)
    assert 100.00 = SysCalls.get_current_x(Stubs)
    assert 200.00 = SysCalls.get_current_y(Stubs)
    assert 300.00 = SysCalls.get_current_z(Stubs)
  end

  test "get positions, KO" do
    expect(Stubs, :get_current_x, 1, fn -> {:error, "L"} end)
    expect(Stubs, :get_current_y, 1, fn -> {:error, "O"} end)
    expect(Stubs, :get_current_z, 1, fn -> {:error, "L"} end)

    assert {:error, "L"} == SysCalls.get_current_x(Stubs)
    assert {:error, "O"} == SysCalls.get_current_y(Stubs)
    assert {:error, "L"} == SysCalls.get_current_z(Stubs)
  end

  test "write_pin" do
    err = {:error, "firmware error?"}

    expect(Stubs, :write_pin, 4, fn pin_num, _, _ ->
      if pin_num == 66 do
        err
      else
        :ok
      end
    end)

    assert :ok = SysCalls.write_pin(Stubs, 1, 0, 1)
    assert :ok = SysCalls.write_pin(Stubs, %{type: "boxled", id: 4}, 0, 1)
    assert :ok = SysCalls.write_pin(Stubs, %{type: "boxled", id: 3}, 1, 123)
    assert err == SysCalls.write_pin(Stubs, 66, 0, 1)
  end

  test "read_pin" do
    expect(Stubs, :read_pin, 3, fn num, _mode ->
      if num == 1 do
        {:error, "firmware error"}
      else
        num * 2
      end
    end)

    assert 20 == SysCalls.read_pin(Stubs, 10, 0)
    assert 30 == SysCalls.read_pin(Stubs, 15, nil)
    assert {:error, "firmware error"} == SysCalls.read_pin(Stubs, 1, 0)
  end

  test "wait" do
    expect(Stubs, :wait, fn ms ->
      if ms == 1000 do
        :ok
      end
    end)

    assert :ok = SysCalls.wait(Stubs, 1000)
  end

  test "named_pin" do
    err = {:error, "error finding resource"}

    expect(Stubs, :named_pin, 5, fn kind, num ->
      hmm = {kind, num}

      case hmm do
        {"Peripheral", 5} -> 44
        {"Sensor", 1999} -> 55
        {"BoxLed", 3} -> %{type: "BoxLed", id: 3}
        {"BoxLed", 4} -> %{type: "BoxLed", id: 4}
        {"Peripheral", 888} -> err
      end
    end)

    # Peripheral and Sensor are on the Arduino
    assert 44 == SysCalls.named_pin(Stubs, "Peripheral", 5)
    assert 55 == SysCalls.named_pin(Stubs, "Sensor", 1999)

    # BoxLed is on the GPIO

    assert %{type: "BoxLed", id: 3} ==
             SysCalls.named_pin(Stubs, "BoxLed", 3)

    assert %{type: "BoxLed", id: 4} ==
             SysCalls.named_pin(Stubs, "BoxLed", 4)

    assert err == SysCalls.named_pin(Stubs, "Peripheral", 888)
  end

  test "send_message" do
    err = {:error, "email machine broke"}

    expect(Stubs, :send_message, 2, fn type, _msg, _chans ->
      if type == "error" do
        err
      else
        :ok
      end
    end)

    assert :ok =
             SysCalls.send_message(Stubs, "success", "hello world", ["email"])

    assert err ==
             SysCalls.send_message(Stubs, "error", "goodbye world", ["email"])
  end

  test "find_home" do
    err = {:error, "home lost"}

    expect(Stubs, :find_home, 2, fn axis ->
      if axis == "x" do
        :ok
      else
        err
      end
    end)

    assert :ok = SysCalls.find_home(Stubs, "x")
    assert err == SysCalls.find_home(Stubs, "z")
  end

  test "execute_script" do
    err = {:error, "not installed"}

    expect(Stubs, :execute_script, 2, fn "take-photo", env ->
      if Map.get(env, :error) do
        err
      else
        :ok
      end
    end)

    assert :ok = SysCalls.execute_script(Stubs, "take-photo", %{})
    assert err == SysCalls.execute_script(Stubs, "take-photo", %{error: true})
  end

  test "set_servo_angle errors" do
    error = {:error, "boom"}

    expect(Stubs, :set_servo_angle, 2, fn num, _val ->
      if num == 5 do
        :ok
      else
        error
      end
    end)

    assert error == SysCalls.set_servo_angle(Stubs, 40, -5)
    assert :ok == SysCalls.set_servo_angle(Stubs, 5, 40)
  end

  test "get_sequence" do
    nothing = %AST{
      kind: "nothing",
      args: {},
      body: []
    }

    err = {:error, "sequence not found"}

    expect(Stubs, :get_sequence, 2, fn sequence_id ->
      if sequence_id == 321 do
        err
      else
        nothing
      end
    end)

    assert nothing == SysCalls.get_sequence(Stubs, 123)
    assert err == SysCalls.get_sequence(Stubs, 321)
  end
end
