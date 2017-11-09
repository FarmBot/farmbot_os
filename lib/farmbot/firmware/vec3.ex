defmodule Farmbot.Firmware.Vec3 do
  @moduledoc "A three position vector."

  defstruct [x: -1, y: -1, z: -1]

  @typedoc "Axis label."
  @type axis :: :x | :y | :z

  @typedoc @moduledoc
  @type t :: %__MODULE__{x: number, y: number, z: number}

  defimpl Inspect, for: __MODULE__ do
    def inspect(vec3, _) do
      "(#{vec3.x}, #{vec3.y}, #{vec3.z})"
    end
  end
end
