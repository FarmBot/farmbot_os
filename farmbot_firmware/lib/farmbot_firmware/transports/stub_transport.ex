defmodule Farmbot.Firmware.StubTransport do
  @moduledoc "Stub for transporting GCODES. Simulates the _real_ Firmware."
  use GenServer

  alias Farmbot.Firmware.StubTransport, as: State
  alias Farmbot.Firmware.{GCODE, Param}
  require Logger

  defstruct status: :boot,
            handle_gcode: nil,
            position: [x: 0, y: 0, z: 0],
            encoders_scaled: [x: 0, y: 0, z: 0],
            encoders_raw: [x: 0, y: 0, z: 0],
            pins: %{},
            params: []

  @type t :: %State{
          status: Farmbot.Firmware.status(),
          handle_gcode: (Farmbot.Firmware.GCODE.t() -> :ok),
          position: [x: float(), y: float(), z: float()],
          encoders_scaled: [x: float(), y: float(), z: float()],
          encoders_raw: [x: float(), y: float(), z: float()],
          pins: %{},
          params: [{Param.t(), float() | nil}]
        }

  def init(args) do
    handle_gcode = Keyword.fetch!(args, :handle_gcode)
    {:ok, %State{status: :boot, handle_gcode: handle_gcode}, 0}
  end

  def handle_info(:timeout, %{status: :boot} = state) do
    state.handle_gcode.(GCODE.new(:report_debug_message, ["ARDUINO STARTUP COMPLETE"]))
    {:noreply, goto(state, :no_config), 0}
  end

  def handle_info(:timeout, %{status: :no_config} = state) do
    state.handle_gcode.(GCODE.new(:report_no_config, []))
    {:noreply, state}
  end

  def handle_info(:timeout, %{status: :idle} = state) do
    resp_codes = [
      GCODE.new(:report_position, state.position),
      GCODE.new(:report_encoders_scaled, state.encoders_scaled),
      GCODE.new(:report_encoders_raw, state.encoders_raw),
      GCODE.new(:report_idle, [])
    ]

    {:noreply, state, {:continue, resp_codes}}
  end

  def handle_call(
        {tag, {:paramater_write, [{:param_config_ok = param, 1.0 = value}]}} = code,
        _from,
        state
      ) do
    new_state = %{state | params: Keyword.put(state.params, param, value)}

    resp_codes = [
      GCODE.new(:report_echo, [GCODE.encode(code)]),
      GCODE.new(:report_begin, [], tag),
      GCODE.new(:report_success, [], tag)
    ]

    {:reply, :ok, goto(new_state, :idle), {:continue, resp_codes}}
  end

  def handle_call({tag, {:paramater_write, [{param, value}]}} = code, _from, state) do
    new_state = %{state | params: Keyword.put(state.params, param, value)}

    resp_codes = [
      GCODE.new(:report_echo, [GCODE.encode(code)]),
      GCODE.new(:report_begin, [], tag),
      GCODE.new(:report_success, [], tag)
    ]

    {:reply, :ok, new_state, {:continue, resp_codes}}
  end

  def handle_call({tag, {:paramater_read_all, []}} = code, _from, state) do
    resp_codes =
      [
        GCODE.new(:report_echo, [GCODE.encode(code)]),
        GCODE.new(:report_begin, [], tag),
        Enum.map(state.params, fn {p, v} ->
          GCODE.new(:report_paramater, [{p, v}])
        end),
        GCODE.new(:report_success, [], tag)
      ]
      |> List.flatten()

    {:reply, :ok, state, {:continue, resp_codes}}
  end

  def handle_call({tag, {:command_movement_find_home, _}} = code, _from, state) do
    resp_codes =
      [
        GCODE.new(:report_echo, [GCODE.encode(code)]),
        GCODE.new(:report_begin, [], tag),
        GCODE.new(:report_success, [], tag)
      ]

    {:reply, :ok, state, {:continue, resp_codes}}
  end

  def handle_call({tag, {:pin_read, [p: p, m: m]}} = code, _from, state) do
    state = case Map.get(state.pins, p) do
      nil -> %{state | pins: Map.put(state.pins, p, [m: m, v: 0])}
      [m: ^m, v: v] -> %{state | pins: Map.put(state.pins, p, [m: m, v: v])}
      _ -> state
    end
    resp_codes =
      [
        GCODE.new(:report_echo, [GCODE.encode(code)]),
        GCODE.new(:report_begin, [], tag),
        GCODE.new(:report_pin_value, [p: p, v: Map.get(state.pins, p)[:v]]),
        GCODE.new(:report_success, [], tag)
      ]
    {:reply, :ok, state, {:continue, resp_codes}}
  end

  def handle_call({tag, {:pin_write, args}} = code, _from, state) do
    p = Keyword.fetch!(args, :p)
    m = Keyword.get(args, :m, state.pins[p][:m] || 0)
    v = Keyword.fetch!(args, :v)
    state =  %{state | pins: Map.put(state.pins, p, [m: m, v: v])}
    resp_codes =
      [
        GCODE.new(:report_echo, [GCODE.encode(code)]),
        GCODE.new(:report_begin, [], tag),
        GCODE.new(:report_success, [], tag)
      ]
    {:reply, :ok, state, {:continue, resp_codes}}
  end

  def handle_call({tag, {:position_read, _}} = code, _from, state) do
    resp_codes =
      [
        GCODE.new(:report_echo, [GCODE.encode(code)]),
        GCODE.new(:report_begin, [], tag),
        GCODE.new(:report_position, state.position),
        GCODE.new(:report_success, [], tag)
      ]
    {:reply, :ok, state, {:continue, resp_codes}}
  end

  def handle_call({tag, {:paramater_read, [param]}} = code, _from, state) do
    resp_codes =
      [
        GCODE.new(:report_echo, [GCODE.encode(code)]),
        GCODE.new(:report_begin, [], tag),
        GCODE.new(:report_paramater_value, [{param, state.params[param] || -1.0}]),
        GCODE.new(:report_success, [], tag)
      ]
    {:reply, :ok, state, {:continue, resp_codes}}
  end

  def handle_call({tag, {:command_movement, args}} = code, _from, state) do
    position = [
      x: args[:x] || state.position[:x],
      y: args[:y] || state.position[:y],
      z: args[:z] || state.position[:z]
    ]
    state = %{state | position: position}
    resp_codes =
      [
        GCODE.new(:report_echo, [GCODE.encode(code)]),
        GCODE.new(:report_begin, [], tag),
        GCODE.new(:report_busy, [], tag),
        GCODE.new(:report_position, state.position),
        GCODE.new(:report_success, [], tag)
      ]
    {:reply, :ok, state, {:continue, resp_codes}}
  end

  def handle_call({tag, {_, _}} = code, _from, state) do
    Logger.error("STUB HANDLER: unknown code: #{inspect(code)} for state: #{state.status}")
    resp_codes =
      [
        GCODE.new(:report_echo, [GCODE.encode(code)]),
        GCODE.new(:report_invalid, [], tag),
      ]
    {:reply, :ok, state, {:continue, resp_codes}}
  end

  def handle_continue([code | rest], state) do
    state.handle_gcode.(code)
    {:noreply, state, {:continue, rest}}
  end

  def handle_continue([], %{status: :idle} = state) do
    {:noreply, state, 5_000}
  end

  def handle_continue([], %{status: _} = state) do
    {:noreply, state}
  end

  defp goto(%{status: _old} = state, status), do: %{state | status: status}
end
