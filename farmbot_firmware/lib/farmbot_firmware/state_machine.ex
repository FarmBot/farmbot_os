defmodule Farmbot.Firmware.StateMachine do
  alias Farmbot.Firmware.{GCODE, Param, StateMachine}

  defstruct [
    :context,
    :op,
    :args,
    :tag,
    :params,
    :position,
    :encoders_scaled,
    :encoders_raw,
    :axis_state,
    :calibration_state,
    :end_stops,
    :pins,
    :status,
    :version
  ]

  @typedoc "Firmware State machine"
  @type t :: %StateMachine{
          context: atom(),
          op: nil | GCODE.kind(),
          args: nil | GCODE.args(),
          tag: GCODE.tag(),
          params: [{Param.t(), float()}],
          position: {float(), float(), float()},
          encoders_scaled: {float(), float(), float()},
          encoders_raw: {float(), float(), float()},
          axis_state: {atom(), atom(), atom()},
          calibration_state: {atom(), atom(), atom()},
          end_stops: {0 | 1, 0 | 1, 0 | 1, 0 | 1, 0 | 1, 0 | 1},
          pins: [{0 | pos_integer(), integer()}],
          status: [{0 | pos_integer(), integer()}],
          version: nil | String.t()
        }

  def new() do
    %StateMachine{
      context: :idle,
      op: nil,
      args: nil,
      tag: "0",
      params: [],
      position: {-1.0, -1.0, -1.0},
      encoders_scaled: {-1.0, -1.0, -1.0},
      encoders_raw: {-1.0, -1.0, -1.0},
      axis_state: {:idle, :idle, :idle},
      calibration_state: {:idle, :idle, :idle},
      end_stops: {0, 0, 0, 0, 0, 0},
      pins: [],
      status: [],
      version: nil
    }
  end

  def handle_gcode(state, {tag, {command, args}}) do
    handle_gcode(%{state | tag: tag}, command, args)
  end

  def handle_gcode(state, :report_idle, []) do
    %{state | context: :idle, op: nil, args: nil}
  end

  def handle_gcode(state, :report_begin, []) do
    %{state | context: :begin}
  end

  def handle_gcode(state, :report_success, []) do
    %{state | op: nil, args: nil}
  end

  def handle_gcode(state, :report_error, []) do
    %{state | op: nil, args: nil}
  end

  def handle_gcode(state, :report_busy, []) do
    %{state | context: :busy}
  end

  def handle_gcode(state, :report_axis_state, x: xstate, y: ystate, z: zstate) do
    %{state | axis_state: {xstate, ystate, zstate}}
  end

  def handle_gcode(state, :report_calibration_state, x: xstate, y: ystate, z: zstate) do
    %{state | calibration_state: {xstate, ystate, zstate}}
  end

  def handle_gcode(state, :report_retry, []) do
    %{state | context: :retry}
  end

  def handle_gcode(state, :report_echo, []) do
    state
  end

  def handle_gcode(state, :report_invalid, []) do
    %{state | op: nil, args: nil}
  end

  def handle_gcode(state, :report_home_complete, _) do
    state
  end

  def handle_gcode(state, :report_position, x: x, y: y, z: z) do
    %{state | position: {x, y, z}}
  end

  def handle_gcode(state, :report_paramaters_complete, []) do
    state
  end

  def handle_gcode(state, :report_paramater, [{param, value}]) do
    %{state | paramaters: Keyword.put(state.paramaters, param, value)}
  end

  def handle_gcode(state, :report_calibration_paramater, [{param, value}]) do
    %{state | paramaters: Keyword.put(state.paramaters, param, value)}
  end

  def handle_gcode(state, :report_status_value, [{status, value}]) do
    %{state | status: Keyword.put(state.status, status, value)}
  end

  def handle_gcode(state, :report_pin_value, [{pin, value}]) do
    %{state | pins: Keyword.put(state.pins, pin, value)}
  end

  def handle_gcode(state, :report_axis_timeout, [_axis]) do
    %{state | context: :timeout}
  end

  def handle_gcode(state, :report_end_stops, xa: xa, xb: xb, ya: ya, yb: yb, za: za, zb: zb) do
    %{state | end_stops: [xa, xb, ya, yb, za, zb]}
  end

  def handle_gcode(state, :report_version, [version]) do
    %{state | version: version}
  end

  def handle_gcode(state, :report_encoders_scaled, x: x, y: y, z: z) do
    %{state | encoders_scaled: {x, y, z}}
  end

  def handle_gcode(state, :report_encoders_raw, x: x, y: y, z: z) do
    %{state | encoders_raw: {x, y, z}}
  end

  def handle_gcode(state, :report_emergency_lock, []) do
    %{state | context: :emergency_lock}
  end

  def handle_gcode(state, :report_no_config, []) do
    %{state | context: :no_config}
  end

  def handle_gcode(state, :report_debug_message, _) do
    state
  end

  def handle_gcode(state, :unknown, _) do
    state
  end
end
