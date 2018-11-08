defmodule Farmbot.Firmware.SideEffects do
  alias Farmbot.Firmware.Param

  @doc "While in state `:boot`, the firmware needs to load its params."
  @callback load_params :: [{Param.t(), float() | nil}]

  @callback handle_position(x: float(), y: float(), z: float()) :: any()
  @callback handle_encoders_scaled(x: float(), y: float(), z: float()) :: any()
  @callback handle_encoders_raw(x: float(), y: float(), z: float()) :: any()
  @callback handle_paramater([{Param.t(), float()}]) :: any()
end
