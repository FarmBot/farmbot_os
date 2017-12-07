defimpl Inspect, for: Farmbot.CeleryScript.AST do
  def inspect(ast, _opts) do
    "#{Module.split(ast.kind) |> List.last}"
    # "##{Module.split(ast.kind) |> List.last}<#{inspect Map.keys(ast.args)}>"
  end
end
