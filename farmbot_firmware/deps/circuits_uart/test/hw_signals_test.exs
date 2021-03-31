Code.require_file("uart_test.exs", __DIR__)

defmodule HWSignalsTest do
  use ExUnit.Case
  alias Circuits.UART

  setup do
    UARTTest.common_setup()
  end

  test "signals has expected fields", %{uart1: uart1} do
    :ok = UART.open(uart1, UARTTest.port1())
    {:ok, signals} = UART.signals(uart1)

    assert Map.has_key?(signals, :dsr)
    assert Map.has_key?(signals, :dtr)
    assert Map.has_key?(signals, :rts)
    assert Map.has_key?(signals, :st)
    assert Map.has_key?(signals, :sr)
    assert Map.has_key?(signals, :cts)
    assert Map.has_key?(signals, :cd)
    assert Map.has_key?(signals, :rng)

    UART.close(uart1)
  end

  test "rts set works", %{uart1: uart1} do
    :ok = UART.open(uart1, UARTTest.port1())

    :ok = UART.set_rts(uart1, true)
    {:ok, signals} = UART.signals(uart1)
    assert true == signals.rts

    :ok = UART.set_rts(uart1, false)
    {:ok, signals} = UART.signals(uart1)
    assert false == signals.rts

    UART.close(uart1)
  end

  test "dtr set works", %{uart1: uart1} do
    :ok = UART.open(uart1, UARTTest.port1())

    :ok = UART.set_dtr(uart1, true)
    {:ok, signals} = UART.signals(uart1)
    assert true == signals.dtr

    :ok = UART.set_dtr(uart1, false)
    {:ok, signals} = UART.signals(uart1)
    assert false == signals.dtr

    UART.close(uart1)
  end

  test "null modem cable wiring", %{uart1: uart1, uart2: uart2} do
    :ok = UART.open(uart1, UARTTest.port1())
    :ok = UART.open(uart2, UARTTest.port2())

    # If this test fails, double check that your null modem cable
    # has RTS connected to CTS, and DTR connected to DSR and CD.

    # RTS -> CTS
    :ok = UART.set_rts(uart1, true)
    # Set isn't instantaneous on real ports
    :timer.sleep(50)
    {:ok, signals} = UART.signals(uart2)
    assert true == signals.cts

    :ok = UART.set_rts(uart1, false)
    :timer.sleep(50)
    {:ok, signals} = UART.signals(uart2)
    assert false == signals.cts

    # DTR -> DSR and CD
    :ok = UART.set_dtr(uart1, true)
    :timer.sleep(50)
    {:ok, signals} = UART.signals(uart2)
    assert true == signals.dsr
    assert true == signals.cd

    :ok = UART.set_dtr(uart1, false)
    :timer.sleep(50)
    {:ok, signals} = UART.signals(uart2)
    assert false == signals.dsr
    assert false == signals.cd

    UART.close(uart1)
    UART.close(uart2)
  end

  test "set break api exists", %{uart1: uart1} do
    # Currently, we can't detect a break signal, so just test
    # that we can call the APIs.
    :ok = UART.open(uart1, UARTTest.port1())

    :ok = UART.set_break(uart1, true)
    :ok = UART.set_break(uart1, false)

    start_time = System.monotonic_time(:millisecond)
    :ok = UART.send_break(uart1, 250)
    duration = System.monotonic_time(:millisecond) - start_time
    assert duration >= 250

    UART.close(uart1)
  end
end
