defmodule FarmbotCeleryScript.Compiler.UpdateResource do
  alias FarmbotCeleryScript.Compiler

  def update_resource(ast, env) do
    resource = Map.fetch!(ast.args, :resource)

    quote do
      p = unquote(destructure_pairs(ast.body, %{}))
      IO.inspect(p, label: "params")
      result = Compiler.compile_ast(unquote(resource), unquote(env))

      FarmbotCeleryScript.SysCalls.update_resource(result.kind, result.id, p)
    end
  end

  defp destructure_pairs([pair | rest], acc) do
    IO.puts("TODO: Need to apply handlebars to `value`s.")
    key = Map.fetch!(pair.args, :label)
    val = Map.fetch!(pair.args, :value)
    next_acc = Map.merge(acc, %{key => val})
    destructure_pairs(rest, next_acc)
  end

  defp destructure_pairs([], acc) do
    acc
  end
end
