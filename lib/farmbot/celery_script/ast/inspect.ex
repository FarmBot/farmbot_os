defimpl Inspect, for: Farmbot.CeleryScript.AST do
  def inspect(ast, _opts) do
    kind = Module.split(ast.kind) |> List.last
    # body = Enum.map(ast.body, &inspect(&1)) |> inspect()
    "#CeleryScript<#{kind}: #{inspect(Map.keys(ast.args))}, #{inspect ast.body}>"
  end
end
