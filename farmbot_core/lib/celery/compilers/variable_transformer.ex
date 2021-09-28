# Ensure that every "location like" CeleryScript variable has
# an x/y/z property at the root of the object.
defmodule FarmbotCore.Celery.Compiler.VariableTransformer do
  alias FarmbotCore.Celery.SysCalls

  def run!(%{ resource_id: id, resource_type: t }) do
    [SysCalls.point(t, id)]
  end


  def run!(%{args: %{pointer_id: id, pointer_type: t}}) do
    [SysCalls.point(t, id)]
  end

  def run!(%{x: _, y: _, z: _} = vec), do: [vec]

  def run!(%{args: %{x: _, y: _, z: _} = args} = vec) do
    [Map.merge(vec, args)]
  end

  def run!(%{args: %{tool_id: tool_id}}) do
    [FarmbotCore.Celery.SysCalls.get_toolslot_for_tool(tool_id)]
  end

  def run!(nil) do
    error = "LUA ERROR: Sequence does not contain variable"
    [%{kind: :error, error: error, x: nil, y: nil, z: nil}, error]
  end

  def run!(other) do
    [other]
  end
end
