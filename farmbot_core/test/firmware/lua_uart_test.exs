defmodule FarmbotCore.Firmware.LuaUARTTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotCore.Firmware.LuaUART

  test "new_uart/2" do
    me = self()

    expect(Circuits.UART, :read, 1, fn pid, timeout ->
      assert pid == me
      assert timeout == 3
      {:ok, "fake UART data"}
    end)

    expect(Circuits.UART, :write, 1, fn pid, data ->
      assert pid == me
      assert data == "anything"
    end)

    expect(Circuits.UART, :close, 1, fn pid ->
      assert pid == me
    end)

    expect(Circuits.UART, :stop, 1, fn pid ->
      assert pid == me
    end)

    raw_obj = LuaUART.new_uart(me)
    new_uart = Map.new(raw_obj)
    assert new_uart.read
    assert new_uart.write
    assert new_uart.close
    assert {["fake UART data"], :fake_lua} == new_uart.read.([3.21], :fake_lua)
    assert {[], :fake_lua} == new_uart.write.(["anything"], :fake_lua)
    assert {[], :fake_lua} == new_uart.close.([], :fake_lua)
  end
end
