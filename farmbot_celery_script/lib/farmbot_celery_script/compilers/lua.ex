defmodule FarmbotCeleryScript.Compiler.Lua do
  alias FarmbotCeleryScript.SysCalls

  def lua(%{args: %{lua: lua}}, _env) do
    quote location: :keep do
      mod = unquote(__MODULE__)
      mod.do_lua(unquote(lua), better_params)
    end
  end

  def do_lua(lua, better_params) do
    go = fn params, label, lua ->
      raw_var = params[label] || missing_var(label)
      # Some nodes do not have an x/y/z prop at the root level.
      # An example of this is the `coordinate` node, which keeps
      # X/Y/Z data inside of `args`:
      #   %AST{ args: %{x: 0, y: 0, z: 0}, body: [], kind: :coordinate }
      extra_stuff = Map.get(raw_var, :args, %{})
      result = Map.merge(extra_stuff, raw_var)
      {[result], lua}
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

  def missing_var("parent") do
    %{error: "This sequence does not have a default variable"}
  end

  def missing_var(label) do
    %{error: "Can't find variable with label #{inspect(label)}"}
  end
end
