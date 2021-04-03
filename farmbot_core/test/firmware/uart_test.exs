defmodule FarmbotCore.Firmware.UARTTest do
  use ExUnit.Case
  alias FarmbotCore.Firmware.UART
  alias FarmbotCore.Firmware.UARTSupport, as: Support

  test "lifecycle" do
    {:ok, pid} = UART.start_link([path: "ttyACM0"], [])
    result = Support.connect(pid)
    assert result == :ok
    Process.sleep(50_000)
  end
end
