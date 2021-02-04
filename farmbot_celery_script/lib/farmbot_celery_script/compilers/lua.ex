defmodule FarmbotCeleryScript.Compiler.Lua do
  alias FarmbotCeleryScript.SysCalls
  alias FarmbotCeleryScript.Compiler.VariableTransformer

  def lua(%{args: %{lua: lua}}, _env) do
    quote location: :keep do
      mod = unquote(__MODULE__)
      mod.do_lua(unquote(lua), better_params)
    end
  end

  def do_lua(lua, better_params) do
    go = fn params, label, lua ->
      {VariableTransformer.run!(params[label]), lua}
    end

    lookup = fn
      [label], lua -> go.(better_params, label, lua)
      [], lua -> go.(better_params, "parent", lua)
      _, _ -> %{error: "Invalid input. Please pass 1 variable name (string)."}
    end

    args = [
      lua,
      [
        [[:variables], lookup],
        [[:variable], lookup]
      ]
    ]

    SysCalls.raw_lua_eval(args)
  end
end
