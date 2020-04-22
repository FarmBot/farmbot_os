defmodule FarmbotCeleryScript.Compiler.UpdateResource do
  alias FarmbotCeleryScript.AST

  def update_resource(ast, _env) do
    params = destructure_pairs(ast.body, %{})
    {id, type} = destructure_resource(Map.fetch!(ast.args, :resource))
    IO.inspect(params)
    IO.inspect(type)
    IO.inspect(id)
    raise "TODO: Convert symbolic `resource` into concrete resource"

    quote do
      # FarmbotCeleryScript.SysCalls.update_resource(
      #   unquote(Compiler.compile_ast(kind, env)),
      #   unquote(Compiler.compile_ast(id, env)),
      #   unquote(Macro.escape(params))
      # )
    end
  end

  defp destructure_resource(%AST{
         kind: :resource,
         args: %{
           resource_id: id,
           resource_type: type
         }
       }) do
    {type, id}
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
