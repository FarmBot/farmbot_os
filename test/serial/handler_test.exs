defmodule Farmbot.Serial.HandlerTest do
  use ExUnit.Case
  alias Nerves.UART
  alias Farmbot.Serial.Handler

  defmodule GcodeMock do
    @moduledoc false
    use GenServer
    def start_link(tty) do
      GenServer.start_link(__MODULE__, tty)
    end

    def init(tty) do
      {:ok, uart} = UART.start_link()
      UART.open(uart, tty)
      UART.configure(uart,
        framing: {UART.Framing.Line, separator: "\r\n"},
        active: true,
        rx_framing_timeout: 500)
      {:ok, %{uart: uart}}
    end

    def handle_info({:nerves_uart, "/dev/tnt1", code}, state) do
      handle_code(code, state.uart)
      {:noreply, state}
    end

    def handle_info(thing, state) do
      IO.inspect thing
      {:noreply, state}
    end

    def handle_code("F83 Q" <> code, uart) do
      UART.write(uart, "R83 mock_fw Q#{code}")
    end

    def handle_code(code, _uart) do
      IO.warn "whoops!: #{inspect code}"
    end

  end

  setup_all do
    {:ok, mock} = GcodeMock.start_link("/dev/tnt1")

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

  test "checks serial availablity", %{handler: handler} do
    bool = Handler.available?(handler)
    assert bool == true
  end

  test "gets the state", %{handler: handler, handler_nerves: nerves} do
    state = Handler.get_state(handler)
    assert state.nerves == nerves
    assert state.tty == "/dev/tnt0"
  end
end
