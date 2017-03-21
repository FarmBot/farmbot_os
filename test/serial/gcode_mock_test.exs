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
    {:ok, %{uart: uart, params: default_params(), position: nil}}
  end

  def invalidate_params(mock) do
    GenServer.call(mock, :invalidate_params)
  end

  defp default_params do
    %{
      "movement_timeout_x" => 100,
      "movement_timeout_y" => 200
    }
  end

  def handle_call(:invalidate_params, _, state) do
    {random_param, _old_value} = Enum.random(state.params)
    new_params = %{state.params | random_param => Enum.random(0..100)}
    IO.inspect state.params
    IO.inspect new_params
    {:reply, :ok, %{state | params: new_params}}
  end

  def handle_info({:nerves_uart, @mock_tty, code}, state) do
    reply = handle_code(code, state)
    case reply do
      {:params, map, reply} ->
        do_reply(reply, state.uart)
        new_params = Map.merge(state.params, map)
        {:noreply, %{state | params: new_params}}

      {:position, pos, reply} ->
        do_reply(reply, state.uart)
        {:noreply, %{state | position: pos}}

      nil ->
        {:noreply, state}

      reply ->
        do_reply(reply, state.uart)
        {:noreply, state}
    end
  end

  defp do_reply([], _uart), do: :ok

  defp do_reply([str | rest], uart) do
    do_reply(str, uart)
    do_reply(rest, uart)
  end

  defp do_reply(str, uart) when is_binary(str) do
    UART.write(uart, str)
  end

  defp handle_code("F83 Q" <> code, _state) do
    "R83 mock_fw Q#{code}"
  end

  defp handle_code("F22 P" <> params, _state) do
    # "F22 P11 V1000 Q8"
    {rest, code} = split_by_q(params)
    # "11 V1000"
    [param_int | [value]] = String.split(rest, " V")

    reply = [ "R01 Q#{code}", "R02 Q#{code}" ]
    {:params, %{param_int => value}, reply}
  end

  defp handle_code("F21 P" <> params, state) do
    # "F21 P12 Q89"
    {rest, code} = split_by_q(params)
    # "12 "
    param_int = String.trim(rest)
    value = (state.params[param_int] || "-1") |> String.trim
    [
      "R01 Q#{code}",
      "R21 P#{param_int} V#{value} Q#{code}",
      "R02 Q#{code}"
    ]
  end

  defp handle_code("F20 Q" <> code, state) do
    reply = Enum.map(state.params, fn({param, value}) ->
      param_int = Farmbot.Serial.Gcode.Parser.parse_param(param)
      "R21 P#{param_int} V#{value} Q#{code}"
    end)
    ["R01 Q#{code}"] ++ reply ++ ["R02 Q#{code}"]
  end

  defp handle_code("G00 " <> params, _state) do
    # G00 X123000 Y0 Z0 S800 QQ35
    {pos, code} = split_by_q(params)
    [rpos | _] = String.split(pos, " S")
    reply = [
      "R01 Q#{code}",
      "R82 #{rpos} Q#{code}",
      "R02 Q#{code}"
    ]
    {:position, rpos, reply}
  end

  defp handle_code(code, _state) do
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
      Process.sleep(500)
    end)

    {:ok, mock: mock, handler: handler, handler_nerves: nerves}
  end

end
