defmodule FarmbotOS.Firmware.LuaUARTTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotOS.Firmware.LuaUART

  test "open/2" do
    lua = %{fake_lua: true}

    expect(Circuits.UART, :start_link, 1, fn ->
      {:ok, self()}
    end)

    expect(Circuits.UART, :open, 1, fn pid, device, opts ->
      assert pid == self()
      assert device == "null"
      assert opts == [{:speed, 300}, {:active, false}]
      :ok
    end)

    result = LuaUART.open(["null", 300.0], lua)
    {[uart, errors], lua2} = result
    refute errors
    assert lua2 == lua
    assert [read: _, close: _, write: _] = uart
  end

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
