defmodule Farmbot.Firmware.Vec3 do
  @moduledoc "A three position vector."

  defstruct [:x, :y, :z]

  @typedoc "Axis label."
  @type axis :: :x | :y | :z

  @typedoc @moduledoc
  @type t :: %__MODULE__{x: number, y: number, z: number}
end
