defmodule FarmbotCore.Celery.Compiler.Lua do
  alias FarmbotCore.Celery.SysCalls
  alias FarmbotCore.Celery.Compiler.{ VariableTransformer, Scope, }

  def lua(%{args: %{lua: lua}}, cs_scope) do
    quote location: :keep do
      # lua.ex
      mod = unquote(__MODULE__)
      mod.do_lua(unquote(lua), unquote(cs_scope))
    end
  end

  def do_lua(lua, cs_scope) do
    go = fn label, lua ->
      {:ok, variable} = Scope.fetch!(cs_scope, label)
      {VariableTransformer.run!(variable), lua}
    end

    lookup = fn
      [label], lua -> go.(label, lua)
      [], lua -> go.("parent", lua)
      _, _ -> %{error: "Invalid input. Please pass 1 variable name (string)."}
    end

    args = [[[:variables], lookup], [[:variable], lookup]]
    SysCalls.perform_lua(lua, args, nil)
  end
end
