defmodule Farmbot.CeleryScript.SysCallsTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.TestSupport.TestSysCalls
  alias Farmbot.CeleryScript.{SysCalls, RuntimeError}

  setup do
    {:ok, shim} = TestSysCalls.checkout()
    [shim: shim]
  end

  test "point", %{shim: shim} do
    :ok = shim_fun_ok(shim, %{x: 100, y: 200, z: 300})
    assert %{x: 100, y: 200, z: 300} = SysCalls.point(TestSysCalls, "Peripheral", 1)
    assert_receive {:point, ["Peripheral", 1]}

    :ok = shim_fun_error(shim, "point error")

    assert_raise RuntimeError, "point error", fn ->
      SysCalls.point(TestSysCalls, "Peripheral", 1)
    end
  end

  test "move_absolute", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.move_absolute(TestSysCalls, 1, 2, 3, 4)
    assert_receive {:move_absolute, [1, 2, 3, 4]}

    :ok = shim_fun_error(shim, "move failed!")

    assert_raise RuntimeError, "move failed!", fn ->
      SysCalls.move_absolute(TestSysCalls, 1, 2, 3, 4)
    end
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

    assert_raise RuntimeError, "firmware error", fn ->
      SysCalls.get_current_x(TestSysCalls)
    end

    assert_raise RuntimeError, "firmware error", fn ->
      SysCalls.get_current_y(TestSysCalls)
    end

    assert_raise RuntimeError, "firmware error", fn ->
      SysCalls.get_current_z(TestSysCalls)
    end
  end

  test "write_pin", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.write_pin(TestSysCalls, 1, 0, 1)
    assert :ok = SysCalls.write_pin(TestSysCalls, {:boxled, 4}, 0, 1)
    assert :ok = SysCalls.write_pin(TestSysCalls, {:boxled, 3}, 1, 123)

    assert_receive {:write_pin, [1, 0, 1]}
    assert_receive {:write_pin, [{:boxled, 4}, 0, 1]}
    assert_receive {:write_pin, [{:boxled, 3}, 1, 123]}

    :ok = shim_fun_error(shim, "firmware error")

    assert_raise RuntimeError, "firmware error", fn ->
      SysCalls.write_pin(TestSysCalls, 1, 0, 1)
    end
  end

  test "read_pin", %{shim: shim} do
    :ok = shim_fun_ok(shim, 1)
    assert 1 == SysCalls.read_pin(TestSysCalls, 10, 0)
    assert 1 == SysCalls.read_pin(TestSysCalls, 77, nil)
    assert_receive {:read_pin, [10, 0]}
    assert_receive {:read_pin, [77, nil]}

    :ok = shim_fun_error(shim, "firmware error")

    assert_raise RuntimeError, "firmware error", fn ->
      SysCalls.read_pin(TestSysCalls, 1, 0)
    end
  end

  test "wait", %{shim: shim} do
    :ok = shim_fun_ok(shim, "this doesn't matter!")
    assert :ok = SysCalls.wait(TestSysCalls, 1000)
    assert_receive {:wait, [1000]}
  end

  test "named_pin", %{shim: shim} do
    # Peripheral and Sensor are on the Arduino
    :ok = shim_fun_ok(shim, 44)
    assert 44 == SysCalls.named_pin(TestSysCalls, "Peripheral", 5)
    assert 44 == SysCalls.named_pin(TestSysCalls, "Sensor", 1999)

    # BoxLed is on the GPIO
    :ok = shim_fun_ok(shim, {:boxled, 3})
    assert {:boxled, 3} == SysCalls.named_pin(TestSysCalls, "BoxLed", 3)

    :ok = shim_fun_ok(shim, {:boxled, 4})
    assert {:boxled, 4} == SysCalls.named_pin(TestSysCalls, "BoxLed", 4)

    assert_receive {:named_pin, ["Peripheral", 5]}
    assert_receive {:named_pin, ["Sensor", 1999]}
    assert_receive {:named_pin, ["BoxLed", 3]}
    assert_receive {:named_pin, ["BoxLed", 4]}

    :ok = shim_fun_error(shim, "error finding resource")

    assert_raise RuntimeError, "error finding resource", fn ->
      SysCalls.named_pin(TestSysCalls, "Peripheral", 888)
    end
  end

  test "send_message", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.send_message(TestSysCalls, "success", "hello world", ["email"])
    assert_receive {:send_message, ["success", "hello world", ["email"]]}

    :ok = shim_fun_error(shim, "email machine broke")

    assert_raise RuntimeError, "email machine broke", fn ->
      SysCalls.send_message(TestSysCalls, "error", "goodbye world", ["email"])
    end
  end

  test "find_home", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.find_home(TestSysCalls, "x", 100)
    assert_receive {:find_home, ["x", 100]}

    :ok = shim_fun_error(shim, "home lost")

    assert_raise RuntimeError, "home lost", fn ->
      SysCalls.find_home(TestSysCalls, "x", 100)
    end
  end

  test "execute_script", %{shim: shim} do
    :ok = shim_fun_ok(shim)
    assert :ok = SysCalls.execute_script(TestSysCalls, "take-photo", %{})
    assert_receive {:execute_script, ["take-photo", %{}]}

    :ok = shim_fun_error(shim, "not installed")

    assert_raise RuntimeError, "not installed", fn ->
      SysCalls.execute_script(TestSysCalls, "take-photo", %{})
    end
  end

  test "get_sequence", %{shim: shim} do
    :ok =
      shim_fun_ok(shim, %{
        kind: :sequence,
        args: %{locals: %{kind: :scope_declaration, args: %{}}}
      })

    assert %{} = SysCalls.get_sequence(TestSysCalls, 123)
    assert_receive {:get_sequence, [123]}

    :ok = shim_fun_error(shim, "sequence not found")

    assert_raise RuntimeError, "sequence not found", fn ->
      SysCalls.get_sequence(TestSysCalls, 123)
    end
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
