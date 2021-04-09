defmodule FarmbotCore.Firmware.UARTCoreTest do
  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

  alias FarmbotCore.Firmware.UARTCore
  alias FarmbotCore.Firmware.UARTCoreSupport, as: Support

  setup :set_mimic_global
  setup :verify_on_exit!

  test "lifecycle" do
    path = "ttyACM0"
    expect(Support, :connect, 1, fn ^path -> {:ok, self()} end)
    {:ok, pid} = UARTCore.start_link([path: path], [])
    assert is_pid(pid)
    noise = fn -> send(pid, "nonsense") end
    expected = "UNEXPECTED FIRMWARE MESSAGE: \"nonsense\""
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

  # test "scratchpad" do
  #   # Use this when debugging a live bot.
  #   IO.puts("\e[H\e[2J\e[3J")
  #   {:ok, _pid} = UARTCore.start_link([path: "ttyACM0"], [])
  #   Process.sleep(50_000)
  # end
end
