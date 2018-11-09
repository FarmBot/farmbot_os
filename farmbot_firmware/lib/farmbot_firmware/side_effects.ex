defmodule Farmbot.Firmware.SideEffects do
  alias Farmbot.Firmware.{GCODE, Param}

  @doc "While in state `:boot`, the firmware needs to load its params."
  @callback load_params :: [{Param.t(), float() | nil}]

  @callback handle_position(x: float(), y: float(), z: float()) :: any()
  @callback handle_encoders_scaled(x: float(), y: float(), z: float()) :: any()
  @callback handle_encoders_raw(x: float(), y: float(), z: float()) :: any()
  @callback handle_paramater([{Param.t(), float()}]) :: any()
  @callback handle_end_stops(xa: 1 | 0, xb: 1 | 0, ya: 0 | 1, yb: 0 | 1, za: 0 | 1, zb: 0 | 1) ::
              any()
  @callback handle_emergency_lock() :: any()
  @callback handle_emergency_unlock() :: any()

  @callback handle_input_gcode(GCODE.t()) :: any()
  @callback handle_output_gcode(GCODE.t()) :: any()
end
