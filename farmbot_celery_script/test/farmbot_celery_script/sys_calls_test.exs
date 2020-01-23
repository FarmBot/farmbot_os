defmodule FarmbotCeleryScript.SysCallsTest do
  use ExUnit.Case, async: false
  use Mimic
  alias FarmbotCeleryScript.{SysCalls, SysCalls.Stubs}

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
    assert_raise FarmbotCeleryScript.RuntimeError, boom
  end

  test "point groups failure" do
    boom = fn -> SysCalls.get_point_group(Stubs, :something_else) end
    assert_raise FarmbotCeleryScript.RuntimeError, boom
  end

  test "point groups success" do
    pg = %{point_ids: [1, 2, 3]}
    result = SysCalls.get_point_group(Stubs, :whatever)
    assert result == pg
  end

  test "move_absolute" do
    assert :ok = SysCalls.move_absolute(Stubs, 1, 2, 3, 4)
    assert_receive {:move_absolute, [1, 2, 3, 4]}

    assert {:error, "move failed!"} ==
             SysCalls.move_absolute(Stubs, 1, 2, 3, 4)
  end

  test "get current positions" do
    assert 100.00 = SysCalls.get_current_x(Stubs)
    assert 100.00 = SysCalls.get_current_y(Stubs)
    assert 100.00 = SysCalls.get_current_z(Stubs)

    assert_receive {:get_current_x, []}
    assert_receive {:get_current_y, []}
    assert_receive {:get_current_z, []}

    assert {:error, "firmware error"} == SysCalls.get_current_x(Stubs)
    assert {:error, "firmware error"} == SysCalls.get_current_y(Stubs)
    assert {:error, "firmware error"} == SysCalls.get_current_z(Stubs)
  end

  test "write_pin" do
    assert :ok = SysCalls.write_pin(Stubs, 1, 0, 1)

    assert :ok = SysCalls.write_pin(Stubs, %{type: "boxled", id: 4}, 0, 1)

    assert :ok = SysCalls.write_pin(Stubs, %{type: "boxled", id: 3}, 1, 123)

    assert_receive {:write_pin, [1, 0, 1]}
    assert_receive {:write_pin, [%{type: "boxled", id: 4}, 0, 1]}
    assert_receive {:write_pin, [%{type: "boxled", id: 3}, 1, 123]}

    assert {:error, "firmware error"} ==
             SysCalls.write_pin(Stubs, 1, 0, 1)
  end

  test "read_pin" do
    assert 1 == SysCalls.read_pin(Stubs, 10, 0)
    assert 1 == SysCalls.read_pin(Stubs, 77, nil)
    assert_receive {:read_pin, [10, 0]}
    assert_receive {:read_pin, [77, nil]}

    assert {:error, "firmware error"} == SysCalls.read_pin(Stubs, 1, 0)
  end

  test "wait" do
    assert :ok = SysCalls.wait(Stubs, 1000)
    assert_receive {:wait, [1000]}
  end

  test "named_pin" do
    # Peripheral and Sensor are on the Arduino
    assert 44 == SysCalls.named_pin(Stubs, "Peripheral", 5)
    assert 44 == SysCalls.named_pin(Stubs, "Sensor", 1999)

    # BoxLed is on the GPIO

    assert %{type: "BoxLed", id: 3} ==
             SysCalls.named_pin(Stubs, "BoxLed", 3)

    assert %{type: "BoxLed", id: 4} ==
             SysCalls.named_pin(Stubs, "BoxLed", 4)

    assert_receive {:named_pin, ["Peripheral", 5]}
    assert_receive {:named_pin, ["Sensor", 1999]}
    assert_receive {:named_pin, ["BoxLed", 3]}
    assert_receive {:named_pin, ["BoxLed", 4]}

    assert {:error, "error finding resource"} ==
             SysCalls.named_pin(Stubs, "Peripheral", 888)
  end

  test "send_message" do
    assert :ok =
             SysCalls.send_message(Stubs, "success", "hello world", [
               "email"
             ])

    assert_receive {:send_message, ["success", "hello world", ["email"]]}

    assert {:error, "email machine broke"} ==
             SysCalls.send_message(Stubs, "error", "goodbye world", [
               "email"
             ])
  end

  test "find_home" do
    assert :ok = SysCalls.find_home(Stubs, "x")
    assert_receive {:find_home, ["x"]}

    assert {:error, "home lost"} == SysCalls.find_home(Stubs, "x")
  end

  test "execute_script" do
    assert :ok = SysCalls.execute_script(Stubs, "take-photo", %{})
    assert_receive {:execute_script, ["take-photo", %{}]}

    assert {:error, "not installed"} ==
             SysCalls.execute_script(Stubs, "take-photo", %{})
  end

  test "set_servo_angle errors" do
    arg0 = [5, 40]
    assert :ok = SysCalls.set_servo_angle(Stubs, "set_servo_angle", arg0)
    assert_receive {:set_servo_angle, arg0}

    arg1 = [40, -5]

    assert {:error, "boom"} ==
             SysCalls.set_servo_angle(Stubs, "set_servo_angle", arg1)
  end

  test "get_sequence" do
    #   kind: :sequence,
    #   args: %{locals: %AST{kind: :scope_declaration, args: %{}}}
    # })
    assert %{} = SysCalls.get_sequence(Stubs, 123)
    assert_receive {:get_sequence, [123]}

    assert {:error, "sequence not found"} ==
             SysCalls.get_sequence(Stubs, 123)
  end
end
