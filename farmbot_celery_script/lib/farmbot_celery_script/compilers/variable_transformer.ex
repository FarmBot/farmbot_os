# Ensure that every "location like" CeleryScript variable has
# an x/y/z property at the root of the object.
defmodule FarmbotCeleryScript.Compiler.VariableTransformer do
  alias FarmbotCore.Asset
  alias FarmbotCeleryScript.SysCalls

  def run!(%{x: _, y: _, z: _} = vec), do: [vec]

  def run!(%{args: %{x: _, y: _, z: _} = args} = vec) do
    [Map.merge(vec, args)]
  end

  @point_keys [
    :gantry_mounted,
    :id,
    :meta,
    :name,
    :openfarm_slug,
    :plant_stage,
    :pointer_type,
    :pullout_direction,
    :radius,
    :tool_id,
    :x,
    :y,
    :z
  ]

  def run!(%{args: %{pointer_id: id}}) do
    point = Map.from_struct(Asset.get_point(id: id))

    reducer = fn key, result ->
      Map.merge(result, %{key => Map.get(point, key)})
    end

    [Enum.reduce(@point_keys, %{}, reducer)]
  end

  def run!(nil) do
    error = "LUA ERROR: Sequence does not contain variable"
    SysCalls.log(error)
    [%{kind: :error, error: error, x: nil, y: nil, z: nil}, error]
  end

  def run!(other) do
    error = "UNEXPECTED VARIABLE SCHEMA: #{inspect(other)}"
    SysCalls.log(error)
    [other, error]
  end
end
