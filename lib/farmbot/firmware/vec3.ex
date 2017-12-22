defmodule Farmbot.Firmware.Vec3 do
  @moduledoc "A three position vector."

  defstruct [x: -1, y: -1, z: -1]

  @typedoc "Axis label."
  @type axis :: :x | :y | :z

  @typedoc @moduledoc
  @type t :: %__MODULE__{x: number, y: number, z: number}

  @compile {:inline, [fmnt_float: 1]}
  def fmnt_float(num) when is_float(num),
    do: :erlang.float_to_binary(num, [:compact, { :decimals, 2 }])

  def fmnt_float(num) when is_number(num), do: num
end

defimpl Inspect, for: Farmbot.Firmware.Vec3 do
  import Farmbot.Firmware.Vec3, only: [fmnt_float: 1]
  def inspect(vec3, _) do
    "(#{fmnt_float(vec3.x)}, #{fmnt_float(vec3.y)}, #{fmnt_float(vec3.z)})"
  end
end
