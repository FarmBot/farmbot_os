defimpl Inspect, for: Farmbot.CeleryScript.AST do
  def inspect(ast, _opts) do
    "#CeleryScript[#{ast.uid}]<#{ast.kind}: #{inspect(Map.keys(ast.args))}>"
  end
end
