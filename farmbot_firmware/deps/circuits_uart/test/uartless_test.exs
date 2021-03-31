defmodule UARTlessTest do
  use ExUnit.Case
  alias Circuits.UART

  # These tests all run with or without a serial port

  test "enumerate returns a map" do
    ports = UART.enumerate()
    assert is_map(ports)
  end

  test "start_link without arguments works" do
    {:ok, pid} = UART.start_link()
    assert is_pid(pid)
  end

  test "open bogus serial port" do
    {:ok, pid} = UART.start_link()
    assert {:error, :enoent} = UART.open(pid, "bogustty")
  end

  test "using a port without opening it" do
    {:ok, pid} = UART.start_link()
    assert {:error, :ebadf} = UART.write(pid, "hello")
    assert {:error, :ebadf} = UART.read(pid)
    assert {:error, :ebadf} = UART.flush(pid)
    assert {:error, :ebadf} = UART.drain(pid)
  end

  test "unopened uart returns a configuration" do
    {:ok, pid} = UART.start_link()
    {name, opts} = UART.configuration(pid)

    assert name == :closed
    assert is_list(opts)

    # Check the defaults
    assert Keyword.get(opts, :active) == true
    assert Keyword.get(opts, :speed) == 9600
    assert Keyword.get(opts, :data_bits) == 8
    assert Keyword.get(opts, :stop_bits) == 1
    assert Keyword.get(opts, :parity) == :none
    assert Keyword.get(opts, :flow_control) == :none
    assert Keyword.get(opts, :framing) == Circuits.UART.Framing.None
    assert Keyword.get(opts, :rx_framing_timeout) == 0
    assert Keyword.get(opts, :id) == :name
  end

  test "find uarts" do
    {:ok, pid} = UART.start_link()
    assert UART.find_pids() == [{pid, :closed}]
  end
end
