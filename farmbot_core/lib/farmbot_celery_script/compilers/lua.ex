defmodule FarmbotCeleryScript.Compiler.Lua do
  alias FarmbotCeleryScript.SysCalls
  alias FarmbotCeleryScript.Compiler.VariableTransformer

  def lua(%{args: %{lua: lua}}, cs_scope) do
    quote location: :keep do
      # lua.ex
      mod = unquote(__MODULE__)
      mod.do_lua(unquote(lua), unquote(cs_scope))
    end
  end

  def do_lua(lua, cs_scope) do
    go = fn params, label, lua ->
      {VariableTransformer.run!(params[label]), lua}
    end

    declarations = cs_scope.declarations
    lookup = fn
      [label], lua -> go.(declarations, label, lua)
      [], lua -> go.(declarations, "parent", lua)
      _, _ -> %{error: "Invalid input. Please pass 1 variable name (string)."}
    end

    args = [[[:variables], lookup], [[:variable], lookup]]
    SysCalls.perform_lua(lua, args, nil)
  end
end
