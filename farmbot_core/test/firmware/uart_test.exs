defmodule FarmbotCore.Firmware.UARTTest do
  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

  alias FarmbotCore.Firmware.UART
  alias FarmbotCore.Firmware.UARTSupport, as: Support

  setup :set_mimic_global
  setup :verify_on_exit!

  test "lifecycle" do
    path = "ttyACM0"
    expect(Support, :connect, 1, fn ^path -> {:ok, self()} end)
    {:ok, pid} = UART.start_link([path: path], [])
    assert is_pid(pid)
    noise = fn -> send(pid, "nonsense") end
    expected = "UNEXPECTED FIRMWARE MESSAGE: \"nonsense\""
    assert capture_log(noise) =~ expected

    state1 = :sys.get_state(pid)
    refute state1.parser.ready

    send(pid, {:circuits_uart, "", "r99 "})
    state2 = :sys.get_state(pid)
    refute state2.parser.ready

    send(pid, {:circuits_uart, "", "ARDUINO startup COMPLETE\r\n"})
    state3 = :sys.get_state(pid)
    assert state3.parser.ready
  end
end
