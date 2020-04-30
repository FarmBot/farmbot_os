defmodule FarmbotCeleryScript.Compiler.UpdateResource do
  alias FarmbotCeleryScript.{Compiler, AST}

  def update_resource(%AST{args: args, body: body}, env) do
    quote do
      unquote(__MODULE__).do_update(
        unquote(Map.fetch!(args, :resource)),
        unquote(unpair(body, %{})),
        unquote(env)
      )
    end
  end

  def do_update(%AST{kind: :identifier} = res, update, env) do
    {name, environ, nil} = Compiler.compile_ast(res, env)
    value = Keyword.fetch!(environ, name)
    %{resource_id: id, resource_type: kind} = value
    FarmbotCeleryScript.SysCalls.update_resource(kind, id, update)
  end

  def do_update(%AST{kind: :resource} = res, update, _) do
    %{resource_id: id, resource_type: kind} = res.args
    FarmbotCeleryScript.SysCalls.update_resource(kind, id, update)
  end

  def do_update(res, _, _) do
    raise "update_resource error. Please notfiy support: #{inspect(res)}"
  end

  defp unpair([pair | rest], acc) do
    IO.puts("TODO: Need to apply handlebars to `value`s.")
    key = Map.fetch!(pair.args, :label)
    val = Map.fetch!(pair.args, :value)
    next_acc = Map.merge(acc, %{key => val})
    unpair(rest, next_acc)
  end

  defp unpair([], acc) do
    acc
  end
end
