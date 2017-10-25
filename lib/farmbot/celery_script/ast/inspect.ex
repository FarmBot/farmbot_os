defimpl Inspect, for: Farmbot.CeleryScript.AST do
  def inspect(ast, _opts) do
    body = Enum.map(ast.body, fn(sub_ast) -> sub_ast.kind end) |> inspect()
    "#CeleryScript<#{ast.kind}: #{inspect(Map.keys(ast.args))}, #{body}>"
  end
end
