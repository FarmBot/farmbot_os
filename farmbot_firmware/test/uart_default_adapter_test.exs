defmodule FarmbotFirmware.UARTDefaultAdapterTest do
  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!
  alias FarmbotFirmware.{UartDefaultAdapter}

  test "delegates" do
    pid = self()
    path = "/dev/null"
    opts1 = UartDefaultAdapter.generate_opts()
    str = "whatever"

    Circuits.UART
    |> expect(:start_link, fn -> nil end)
    |> expect(:open, fn uart_pid, device_path, opts ->
      assert uart_pid == pid
      assert device_path == path
      assert opts == opts1
      nil
    end)
    |> expect(:stop, fn uart_pid ->
      assert uart_pid == pid
      nil
    end)
    |> expect(:write, fn uart_pid, data ->
      assert uart_pid == pid
      assert data == str
      nil
    end)

    UartDefaultAdapter.start_link()
    UartDefaultAdapter.open(pid, path, opts1)
    UartDefaultAdapter.stop(pid)
    UartDefaultAdapter.write(pid, str)
  end
end
