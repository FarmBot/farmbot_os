defmodule FarmbotCore.Firmware.UARTCoreSupportTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotCore.Firmware.{
    UARTCoreSupport,
    UARTCore
  }

  test "disconnect/2" do
    me = self()
    assert_is_me = fn uart -> assert uart == me end
    fake_uart = "ttyNull0"

    Circuits.UART
    # |> expect(:find_pids, 1, fn -> [{me, fake_uart}] end)
    |> expect(:close, 1, assert_is_me)
    # |> expect(:drain, 1, assert_is_me)
    # |> expect(:flush, 1, assert_is_me)
    # |> expect(:send_break, 1, assert_is_me)
    |> expect(:stop, 1, assert_is_me)

    state = %UARTCore{
      uart_path: fake_uart,
      uart_pid: me
    }

    result = UARTCoreSupport.disconnect(state, "It's a unit test")
    assert {:ok, fake_uart} == result
  end
end
