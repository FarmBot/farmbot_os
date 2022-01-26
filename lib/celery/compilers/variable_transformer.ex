# Ensure that every "location like" CeleryScript variable has
# an x/y/z property at the root of the object.
defmodule FarmbotOS.Celery.Compiler.VariableTransformer do
  alias FarmbotOS.Celery.SysCallGlue
  alias FarmbotOS.Asset.Repo

  require FarmbotOS.Logger

  def run!(%{resource_id: id, resource_type: t}) do
    [SysCallGlue.point(t, id)]
  end

  def run!(%{args: %{pointer_id: id, pointer_type: t}}) do
    [SysCallGlue.point(t, id)]
  end

  def run!(%{x: _, y: _, z: _} = vec), do: [vec]

  def run!(%{args: %{x: _, y: _, z: _} = args} = vec) do
    [Map.merge(vec, args)]
  end

  def run!(%{args: %{tool_id: tool_id}}) do
    [FarmbotOS.Celery.SysCallGlue.get_toolslot_for_tool(tool_id)]
  end

  def run!(%{args: %{number: number}}) do
    [number]
  end

  def run!(%{args: %{string: string}}) do
    [string]
  end

  def run!(nil) do
    error = "LUA ERROR: Sequence does not contain variable"
    [%{kind: :error, error: error, x: nil, y: nil, z: nil}, error]
  end

  def run!(%{args: %{resource_id: id, resource_type: t}} = misc) do
    mod = Module.concat(FarmbotOS.Asset, t)
    is_known_resource? = Kernel.function_exported?(mod, :render, 1)

    if is_known_resource? do
      result = Repo.get_by(mod, id: id)

      if result do
        [result]
      else
        msg = "Could not find #{t} #{id}. Did you delete it?"
        FarmbotOS.Logger.info(3, msg)
        [nil]
      end
    else
      # There was a typo, or the sequence is handling a resource
      # that FarmBot OS does not know about.
      [misc]
    end
  end

  def run!(other) do
    [other]
  end
end
