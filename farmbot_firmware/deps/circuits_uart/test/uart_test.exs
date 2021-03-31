defmodule UARTTest do
  use ExUnit.Case
  alias Circuits.UART

  @moduledoc """
  This module provides common setup code for unit tests that require real
  or emulated serial ports to work.

  Define the following environment variables for your environment:

    CIRCUITS_UART_PORT1 - e.g., COM1 or ttyS0
    CIRCUITS_UART_PORT2

  The unit tests expect those ports to exist, be different ports,
  and be connected to each other through a null modem cable.

  On Linux, it's possible to use tty0tty. See
  https://github.com/freemed/tty0tty.
  """

  def port1() do
    System.get_env("CIRCUITS_UART_PORT1")
  end

  def port2() do
    System.get_env("CIRCUITS_UART_PORT2")
  end

  def common_setup() do
    if is_nil(port1()) || is_nil(port2()) do
      header = "Please define CIRCUITS_UART_PORT1 and CIRCUITS_UART_PORT2 in your
  environment (e.g. to ttyS0 or COM1) and connect them via a null
  modem cable.\n\n"

      ports = UART.enumerate()

      msg =
        case ports do
          [] -> header <> "No serial ports were found. Check your OS to see if they exist"
          _ -> header <> "The following ports were found: #{inspect(Map.keys(ports))}"
        end

      flunk(msg)
    end

    if !String.starts_with?(port1(), "tnt") do
      # Let things settle between tests for real serial ports
      :timer.sleep(500)
    end

    {:ok, uart1} = UART.start_link()
    {:ok, uart2} = UART.start_link()
    {:ok, uart1: uart1, uart2: uart2}
  end
end
