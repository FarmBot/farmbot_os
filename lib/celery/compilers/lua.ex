defmodule FarmbotOS.Celery.Compiler.Lua do
  alias FarmbotOS.Celery.SysCallGlue
  alias FarmbotOS.Celery.Compiler.{VariableTransformer, Scope}

  def lua(%{args: %{lua: lua}}, cs_scope) do
    quote location: :keep do
      # lua.ex
      mod = unquote(__MODULE__)
      mod.do_lua(unquote(lua), unquote(cs_scope))
    end
  end

  # Convert a CeleryScript scope object to a Luerl table
  # structure.
  def scope_to_lua(cs_scope) do
    # Alias `variable()` and `variables()` for convenience.
    aliases = [:variable, :variables]
    lookup = generate_lookup_fn(cs_scope)
    Enum.map(aliases, fn name -> [[name], lookup] end)
  end

  def do_lua(lua_state, cs_scope) do
    SysCallGlue.perform_lua(lua_state, scope_to_lua(cs_scope), nil)
  end

  def generate_lookup_fn(cs_scope) do
    go = fn label, lua ->
      {:ok, variable} = Scope.fetch!(cs_scope, label)
      {VariableTransformer.run!(variable), lua}
    end

    fn
      [label], lua -> go.(label, lua)
      [], lua -> go.("parent", lua)
      _, _ -> %{error: "Invalid input. Please pass 1 variable name (string)."}
    end
  end
end
