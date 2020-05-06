defmodule FarmbotCeleryScript.Compiler.UpdateResource do
  alias FarmbotCeleryScript.{Compiler, AST, DotProps}

  def update_resource(%AST{args: args, body: body}, env) do
    quote do
      unquote(__MODULE__).do_update_resource(
        unquote(Map.fetch!(args, :resource)),
        unquote(unpair(body, %{})),
        unquote(env)
      )
    end
  end

  def do_update_resource(%AST{kind: :identifier} = variable, update, env) do
    {name, environ, nil} = Compiler.compile_ast(variable, env)
    value = Keyword.fetch!(environ, name)
    run_update_syscall(value, update)
  end

  def do_update_resource(%AST{kind: :resource} = res, update, _) do
    run_update_syscall(res.args, update)
  end

  def do_update_resource(res, _, _) do
    raise "update_resource error. Please notfiy support: #{inspect(res)}"
  end

  defp run_update_syscall(%{resource_id: id, resource_type: kind}, update_params) do
    FarmbotCeleryScript.SysCalls.update_resource(kind, id, update_params)
  end

  defp run_update_syscall(other, update) do
    raise String.trim("""
    MARK AS can only be used to mark resources like plants and devices.
    It cannot be used on things like coordinates.
    Ensure that your sequences and farm events us MARK AS on plants and not
    coordinates. Tried updating #{inspect(other)} to #{inspect(update)}
    """)
  end

  defp unpair([pair | rest], acc) do
    IO.puts("TODO: Need to apply handlebars to `value`s.")
    key = Map.fetch!(pair.args, :label)
    val = Map.fetch!(pair.args, :value)
    next_acc = Map.merge(acc, DotProps.create(key, val))
    unpair(rest, next_acc)
  end

  defp unpair([], acc) do
    acc
  end
end
