defmodule FarmbotCeleryScript.Compiler.UpdateResource do
  def update_resource(ast, _env) do
    quote do
      FarmbotCeleryScript.SysCalls.update_resource(
        unquote(Map.fetch!(ast.args, :resource)),
        unquote(destructure_pairs(ast.body, %{}))
      )
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
