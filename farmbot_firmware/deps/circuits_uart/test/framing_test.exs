Code.require_file("uart_test.exs", __DIR__)

defmodule FramingTest do
  use ExUnit.Case
  alias Circuits.UART

  @moduledoc """
  These tests are high level framing tests. See `framing_*_test.exs`
  for unit tests.
  """

  setup do
    UARTTest.common_setup()
  end

  test "receive a line in passive mode", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1())

    assert :ok =
             UART.open(
               uart2,
               UARTTest.port2(),
               active: false,
               framing: {
                 UART.Framing.Line,
                 max_length: 4
               }
             )

    # Send something that's not a line and check that we don't receive it
    assert :ok = UART.write(uart1, "A")
    assert {:ok, <<>>} = UART.read(uart2, 500)

    # Terminate the line and check that receive gets it
    assert :ok = UART.write(uart1, "\n")
    assert {:ok, "A"} = UART.read(uart2)

    # Send two lines
    assert :ok = UART.write(uart1, "B\nC\n")
    assert {:ok, "B"} = UART.read(uart2, 500)
    assert {:ok, "C"} = UART.read(uart2, 500)

    # Handle a line that's too long
    assert :ok = UART.write(uart1, "DEFGHIJK\n")
    assert {:ok, {:partial, "DEFG"}} = UART.read(uart2, 500)
    assert {:ok, "HIJK"} = UART.read(uart2, 500)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "framing gets applied when transmitting", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1(), framing: UART.Framing.Line)
    assert :ok = UART.open(uart2, UARTTest.port2(), active: false)

    # Transmit something and check that a linefeed gets applied
    assert :ok = UART.write(uart1, "A")
    :timer.sleep(100)
    assert {:ok, "A\n"} = UART.read(uart2)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "multiple read polls do not elapse the specified read timeout", %{
    uart1: uart1,
    uart2: uart2
  } do
    assert :ok = UART.open(uart1, UARTTest.port1())

    assert :ok =
             UART.open(
               uart2,
               UARTTest.port2(),
               active: false,
               framing: {
                 UART.Framing.Line,
                 max_length: 4
               }
             )

    spawn(fn ->
      # Sleep to allow the UART.read some time to begin reading
      :timer.sleep(100)
      # Send something that's not a line
      assert :ok = UART.write(uart1, "A")
    end)

    assert {:ok, <<>>} = UART.read(uart2, 500)
  end

  test "framing timeouts in passive mode", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1())

    assert :ok =
             UART.open(
               uart2,
               UARTTest.port2(),
               active: false,
               framing: {UART.Framing.Line, max_length: 10},
               rx_framing_timeout: 100
             )

    # Send something that's not a line and check that it times out
    assert :ok = UART.write(uart1, "A")
    # Initial read will timeout and the partial read will be queued in the uart state
    assert {:ok, <<>>} = UART.read(uart2, 200)
    # Call read again to fetch the queued data
    assert {:ok, {:partial, "A"}} = UART.read(uart2, 200)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "receive a line in active mode", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1())

    assert :ok =
             UART.open(
               uart2,
               UARTTest.port2(),
               active: true,
               framing: {
                 UART.Framing.Line,
                 max_length: 4
               }
             )

    port2 = UARTTest.port2()

    # Send something that's not a line and check that we don't receive it
    assert :ok = UART.write(uart1, "A")
    refute_receive {:circuits_uart, _, _}

    # Terminate the line and check that receive gets it
    assert :ok = UART.write(uart1, "\n")
    # QUESTION: Trim the framing or not?
    #    Argument to trim: 1. the framing is at a lower level
    #                      2. framing could contain stuffing, compression, etc.
    #                         that would need to be undone anyway. not removing
    #                         the framing would effectively mean that the
    #                         framing gets removed twice.
    #                      3. Erlang ports remove their framing
    #    Argument not to trim: 1. most framing is easy to trim anyway
    #                          2. easier to debug?
    assert_receive {:circuits_uart, ^port2, "A"}

    # Send two lines
    assert :ok = UART.write(uart1, "B\nC\n")
    assert_receive {:circuits_uart, ^port2, "B"}
    assert_receive {:circuits_uart, ^port2, "C"}

    # Handle a line that's too long
    assert :ok = UART.write(uart1, "DEFGHIJK\n")
    assert_receive {:circuits_uart, ^port2, {:partial, "DEFG"}}
    assert_receive {:circuits_uart, ^port2, "HIJK"}

    UART.close(uart1)
    UART.close(uart2)
  end

  test "framing timeouts in active mode", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, UARTTest.port1())

    assert :ok =
             UART.open(
               uart2,
               UARTTest.port2(),
               active: true,
               framing: {UART.Framing.Line, max_length: 10},
               rx_framing_timeout: 500
             )

    port2 = UARTTest.port2()

    # Send something that's not a line and check that it times out
    assert :ok = UART.write(uart1, "A")
    assert_receive {:circuits_uart, ^port2, {:partial, "A"}}, 1000

    UART.close(uart1)
    UART.close(uart2)
  end

  test "active mode gets error when write fails", %{uart1: uart1} do
    # This only works with tty0tty since it fails write operations if no
    # receiver.

    if String.starts_with?(UARTTest.port1(), "tnt") do
      assert :ok = UART.open(uart1, UARTTest.port1(), active: true, framing: UART.Framing.Line)
      port1 = UARTTest.port1()

      assert {:error, :einval} = UART.write(uart1, "a")
      assert_receive {:circuits_uart, ^port1, {:error, :einval}}

      UART.close(uart1)
    end
  end
end
