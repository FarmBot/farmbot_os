defmodule GcodeMockTest do
  @moduledoc false

  use ExUnit.Case
  alias Nerves.UART
  alias Farmbot.Serial.Handler
  @mock_tty "/dev/tnt1"
  use GenServer
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    tty = @mock_tty
    {:ok, uart} = UART.start_link()
    UART.open(uart, tty)
    UART.configure(uart,
      framing: {UART.Framing.Line, separator: "\r\n"},
      active: true,
      rx_framing_timeout: 500)
    {:ok, %{uart: uart, mocks: %{}}}
  end

  def handle_info({:nerves_uart, @mock_tty, code}, state) do
    reply = handle_code(code)
    if reply, do: do_reply(reply, state.uart)
    {:noreply, state}
  end

  defp do_reply([], _), do: :ok

  defp do_reply([str | rest], uart) do
    do_reply(str, uart)
    do_reply(rest, uart)
  end

  defp do_reply(str, uart) when is_binary(str) do
    UART.write(uart, str)
  end

  defp handle_code("F83 Q" <> code) do
    "R83 mock_fw Q#{code}"
  end

  defp handle_code("G00 " <> params) do
    # G00 X123000 Y0 Z0 S800 QQ35
    {pos, code} = split_by_q(params)
    [rpos | _] = String.split(pos, " S")
    [
      "R01 Q#{code}",
      "R82 #{rpos} Q#{code}",
      "R02 Q#{code}"
    ]

  end

  defp handle_code(code) do
    IO.warn "whoops!: #{inspect code}"
    "!-!-!-ERROR-!-!-!"
  end

  defp split_by_q(params) do
    [params| [code]] = String.split(params, "Q")
    {params, code}
  end

  def common_setup do
    {:ok, mock} = GcodeMockTest.start_link()

    # start a nerves genserver
    {:ok, nerves} = UART.start_link()
    {:ok, handler} = Handler.start_link(nerves, "/dev/tnt0")

    on_exit(fn() ->
      if Process.alive?(mock) do
        GenServer.stop(mock, :normal)
      end

      if Process.alive?(handler) do
        GenServer.stop(handler, :normal)
      end
    end)

    {:ok, mock: mock, handler: handler, handler_nerves: nerves}
  end

end
