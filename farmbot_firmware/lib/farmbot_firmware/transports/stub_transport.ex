defmodule Farmbot.Firmware.StubTransport do
  @moduledoc "Stub for transporting GCODES. Simulates the _real_ Firmware."
  use GenServer

  alias Farmbot.Firmware.StubTransport, as: State
  alias Farmbot.Firmware.{GCODE, Param}
  require Logger

  defstruct status: :boot,
            handle_gcode: nil,
            params: []

  @type t :: %State{
          status: Farmbot.Firmware.status(),
          handle_gcode: (Farmbot.Firmware.GCODE.t() -> :ok),
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
      GCODE.new(:report_position, x: 0.0, y: 0.0, z: 0.0),
      GCODE.new(:report_encoders_scaled, x: 0.0, y: 0.0, z: 0.0),
      GCODE.new(:report_encoders_raw, x: 0.0, y: 0.0, z: 0.0),
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

  def handle_call({_, {_, _}} = code, _from, state) do
    Logger.error("STUB HANDLER: unknown code: #{inspect(code)} for state: #{state.status}")
    {:reply, :ok, state}
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
