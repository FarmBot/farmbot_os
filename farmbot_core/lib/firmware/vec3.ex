defmodule Farmbot.Firmware.Vec3 do
  @moduledoc "A three position vector."
  alias Farmbot.Firmware.Vec3

  defstruct [x: -1.0, y: -1.0, z: -1.0]

  @typedoc "Axis label."
  @type axis :: :x | :y | :z

  @typedoc @moduledoc
  @type t :: %__MODULE__{x: number, y: number, z: number}

  def new(x, y, z) do
    %Vec3{x: x, y: y, z: z}
  end
end

defimpl Inspect, for: Farmbot.Firmware.Vec3 do
  import Farmbot.Firmware.Utils, only: [fmnt_float: 1]
  def inspect(vec3, _) do
    "(#{fmnt_float(vec3.x)}, #{fmnt_float(vec3.y)}, #{fmnt_float(vec3.z)})"
  end
end

defimpl String.Chars, for: Farmbot.Firmware.Vec3 do
  import Farmbot.Firmware.Utils, only: [fmnt_float: 1]
  def to_string(vec3) do
    "(#{fmnt_float(vec3.x)}, #{fmnt_float(vec3.y)}, #{fmnt_float(vec3.z)})"
  end
end
