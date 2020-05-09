defmodule FarmbotCeleryScript.Compiler.UpdateResource do
  alias FarmbotCeleryScript.{Compiler, AST, DotProps}

  def update_resource(%AST{args: args, body: body}, env) do
    quote location: :keep do
      me = unquote(__MODULE__)
      variable = unquote(Map.fetch!(args, :resource))
      update = unquote(unpair(body, %{}))

      case variable do
        %AST{kind: :identifier} ->
          {name, environ, nil} = Compiler.compile_ast(variable, params)
          me.do_update(Keyword.fetch!(environ, name), update)

        %AST{kind: :resource} ->
          me.do_update(variable.args, update)

        res ->
          raise "Resource error. Please notfiy support: #{inspect(res)}"
      end
    end
  end

  def do_update(%{resource_id: id, resource_type: kind}, update_params) do
    FarmbotCeleryScript.SysCalls.update_resource(kind, id, update_params)
  end

  def do_update(other, update) do
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
