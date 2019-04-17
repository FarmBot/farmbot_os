defmodule FarmbotFirmware.SideEffects do
  @moduledoc """
  Callback functions that the firmware process will call on certain events.
  """

  alias FarmbotFirmware.{GCODE, Param}

  @type axis :: :x | :y | :z

  @doc "While in state `:boot`, the firmware needs to load its params."
  @callback load_params :: [{Param.t(), float() | nil}]

  @callback handle_position(x: float(), y: float(), z: float()) :: any()
  @callback handle_position_change([{axis(), float()}]) :: any()
  @callback handle_encoders_scaled(x: float(), y: float(), z: float()) :: any()
  @callback handle_encoders_raw(x: float(), y: float(), z: float()) :: any()
  @callback handle_parameter_value([{Param.t(), float()}]) :: any()
  @callback handle_parameter_calibration_value([{Param.t(), float()}]) :: any()
  @callback handle_end_stops(xa: 0 | 1, xb: 0 | 1, ya: 0 | 1, yb: 0 | 1, za: 0 | 1, zb: 0 | 1) ::
              any()
  @callback handle_emergency_lock() :: any()
  @callback handle_emergency_unlock() :: any()
  @callback handle_pin_value(p: integer(), v: integer()) :: any()
  @callback handle_software_version([String.t()]) :: any()
  @callback handle_busy(boolean()) :: any()
  @callback handle_idle(boolean()) :: any()

  @type axis_state :: :stop | :idle | :begin | :crawl | :decelerate | :accelerate
  @callback handle_axis_state([{axis(), axis_state}]) :: any()

  @type calibration_state :: :idle | :home | :end
  @callback handle_calibration_state([{axis(), calibration_state()}]) :: any()

  @callback handle_input_gcode(GCODE.t()) :: any()
  @callback handle_output_gcode(GCODE.t()) :: any()
  @callback handle_debug_message([String.t()]) :: any()
end
