defmodule FarmbotCore.Firmware.UARTCoreTest do
  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

  alias FarmbotCore.Firmware.UARTCore
  alias FarmbotCore.Firmware.UARTCoreSupport, as: Support

  setup :set_mimic_global
  setup :verify_on_exit!
  @path "ttyACM0"

  test "lifecycle" do
    expect(Support, :connect, 1, fn @path -> {:ok, self()} end)
    {:ok, pid} = UARTCore.start_link([path: @path], [])
    assert is_pid(pid)
    noise = fn -> send(pid, "nonsense") end
    expected = "UNEXPECTED FIRMWARE MESSAGE: \"nonsense\""
    Process.sleep(300)
    assert capture_log(noise) =~ expected

    state1 = :sys.get_state(pid)
    refute state1.rx_buffer.ready

    send(pid, {:circuits_uart, "", "r99 "})
    state2 = :sys.get_state(pid)
    refute state2.rx_buffer.ready

    send(pid, {:circuits_uart, "", "ARDUINO startup COMPLETE\r\n"})
    state3 = :sys.get_state(pid)
    assert state3.rx_buffer.ready
  end
end
