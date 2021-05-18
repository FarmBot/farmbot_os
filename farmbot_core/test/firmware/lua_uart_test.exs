defmodule FarmbotCore.Firmware.LuaUARTTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotCore.Firmware.LuaUART

  test "new_uart/2" do
    pid = self()
    raw_obj = LuaUART.new_uart(pid)
    new_uart = Map.new(raw_obj)
    assert new_uart.read
    assert new_uart.write
    assert new_uart.close
  end
end
