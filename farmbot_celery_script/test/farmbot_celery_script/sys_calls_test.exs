defmodule FarmbotCeleryScript.SysCallsTest do
  use ExUnit.Case, async: false
  alias Farmbot.TestSupport.CeleryScript.TestSysCalls
  alias FarmbotCeleryScript.{AST, SysCalls}

  setup do
    {:ok, shim} = TestSysCalls.checkout()
    [shim: shim]
  end

  test "point", %{shim: shim} do
    :ok = shim_fun_ok(shim, %{x: 100, y: 200, z: 300})
    assert %{x: 100, y: 200, z: 300} = SysCalls.point(TestSysCalls, "Peripheral", 1)
    assert_receive {:point, ["Peripheral", 1]}

    :ok = shim_fun_error(shim, "point error")

    assert {:error, "point error"} == SysCalls.point(TestSysCalls, "Peripheral", 1)
  end

  test "move_absolute", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.move_absolute(TestSysCalls, 1, 2, 3, 4)
    assert_receive {:move_absolute, [1, 2, 3, 4]}

    :ok = shim_fun_error(shim, "move failed!")

    assert {:error, "move failed!"} == SysCalls.move_absolute(TestSysCalls, 1, 2, 3, 4)
  end

  test "get current positions", %{shim: shim} do
    :ok = shim_fun_ok(shim, 100.00)
    assert 100.00 = SysCalls.get_current_x(TestSysCalls)
    assert 100.00 = SysCalls.get_current_y(TestSysCalls)
    assert 100.00 = SysCalls.get_current_z(TestSysCalls)

    assert_receive {:get_current_x, []}
    assert_receive {:get_current_y, []}
    assert_receive {:get_current_z, []}

    :ok = shim_fun_error(shim, "firmware error")

    assert {:error, "firmware error"} == SysCalls.get_current_x(TestSysCalls)
    assert {:error, "firmware error"} == SysCalls.get_current_y(TestSysCalls)
    assert {:error, "firmware error"} == SysCalls.get_current_z(TestSysCalls)
  end

  test "write_pin", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.write_pin(TestSysCalls, 1, 0, 1)
    assert :ok = SysCalls.write_pin(TestSysCalls, %{type: "boxled", id: 4}, 0, 1)
    assert :ok = SysCalls.write_pin(TestSysCalls, %{type: "boxled", id: 3}, 1, 123)

    assert_receive {:write_pin, [1, 0, 1]}
    assert_receive {:write_pin, [%{type: "boxled", id: 4}, 0, 1]}
    assert_receive {:write_pin, [%{type: "boxled", id: 3}, 1, 123]}

    :ok = shim_fun_error(shim, "firmware error")

    assert {:error, "firmware error"} == SysCalls.write_pin(TestSysCalls, 1, 0, 1)
  end

  test "read_pin", %{shim: shim} do
    :ok = shim_fun_ok(shim, 1)
    assert 1 == SysCalls.read_pin(TestSysCalls, 10, 0)
    assert 1 == SysCalls.read_pin(TestSysCalls, 77, nil)
    assert_receive {:read_pin, [10, 0]}
    assert_receive {:read_pin, [77, nil]}

    :ok = shim_fun_error(shim, "firmware error")

    assert {:error, "firmware error"} == SysCalls.read_pin(TestSysCalls, 1, 0)
  end

  test "wait", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.wait(TestSysCalls, 1000)
    assert_receive {:wait, [1000]}
  end

  test "named_pin", %{shim: shim} do
    # Peripheral and Sensor are on the Arduino
    :ok = shim_fun_ok(shim, 44)
    assert 44 == SysCalls.named_pin(TestSysCalls, "Peripheral", 5)
    assert 44 == SysCalls.named_pin(TestSysCalls, "Sensor", 1999)

    # BoxLed is on the GPIO
    :ok = shim_fun_ok(shim, %{type: "BoxLed", id: 3})
    assert %{type: "BoxLed", id: 3} == SysCalls.named_pin(TestSysCalls, "BoxLed", 3)

    :ok = shim_fun_ok(shim, %{type: "BoxLed", id: 4})
    assert %{type: "BoxLed", id: 4} == SysCalls.named_pin(TestSysCalls, "BoxLed", 4)

    assert_receive {:named_pin, ["Peripheral", 5]}
    assert_receive {:named_pin, ["Sensor", 1999]}
    assert_receive {:named_pin, ["BoxLed", 3]}
    assert_receive {:named_pin, ["BoxLed", 4]}

    :ok = shim_fun_error(shim, "error finding resource")

    assert {:error, "error finding resource"} ==
             SysCalls.named_pin(TestSysCalls, "Peripheral", 888)
  end

  test "send_message", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.send_message(TestSysCalls, "success", "hello world", ["email"])
    assert_receive {:send_message, ["success", "hello world", ["email"]]}

    :ok = shim_fun_error(shim, "email machine broke")

    assert {:error, "email machine broke"} ==
             SysCalls.send_message(TestSysCalls, "error", "goodbye world", ["email"])
  end

  test "find_home", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.find_home(TestSysCalls, "x")
    assert_receive {:find_home, ["x"]}

    :ok = shim_fun_error(shim, "home lost")

    assert {:error, "home lost"} == SysCalls.find_home(TestSysCalls, "x")
  end

  test "execute_script", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.execute_script(TestSysCalls, "take-photo", %{})
    assert_receive {:execute_script, ["take-photo", %{}]}

    :ok = shim_fun_error(shim, "not installed")

    assert {:error, "not installed"} == SysCalls.execute_script(TestSysCalls, "take-photo", %{})
  end

  test "get_sequence", %{shim: shim} do
    :ok =
      shim_fun_ok(shim, %AST{
        kind: :sequence,
        args: %{locals: %AST{kind: :scope_declaration, args: %{}}}
      })

    assert %{} = SysCalls.get_sequence(TestSysCalls, 123)
    assert_receive {:get_sequence, [123]}

    :ok = shim_fun_error(shim, "sequence not found")

    assert {:error, "sequence not found"} == SysCalls.get_sequence(TestSysCalls, 123)
  end

  def shim_fun_ok(shim, val \\ :ok) do
    pid = self()

    :ok =
      TestSysCalls.handle(shim, fn kind, args ->
        send(pid, {kind, args})
        val
      end)
  end

  def shim_fun_error(shim, val) when is_binary(val) do
    :ok =
      TestSysCalls.handle(shim, fn _kind, _args ->
        {:error, val}
      end)
  end
end
