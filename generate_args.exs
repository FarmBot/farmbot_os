args = Farmbot.HTTP.get!("/api/corpuses/4").body |> Poison.decode! |> Map.get("args") |> Enum.map(&Map.get(&1, "name"))
nodes = Farmbot.HTTP.get!("/api/corpuses/4").body |> Poison.decode! |> Map.get("nodes")

arg_template = """
defmodule Farmbot.CeleryScript.AST.Arg.<%= arg %> do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(val), do: {:ok, val}
end
"""

node_template = """
defmodule Farmbot.CeleryScript.AST.Node.<%= node %> do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [<%= allowed_args %>]
end
"""

for arg <- args do
  camel_arg = Macro.camelize(arg)
  str = EEx.eval_string(arg_template, [arg: camel_arg])
  File.write!("lib/farmbot/celery_script/ast/arg/#{arg}.ex", str)
  # |> Code.eval_string()
end

for node <- nodes do
  camel_node = Macro.camelize(node["name"])
  allowed_args = Map.get(node, "allowed_args") |> Enum.map(fn(arg_str) -> ":#{arg_str}" end) |> Enum.join(", ")
  str = EEx.eval_string(node_template, [allowed_args: allowed_args, node: camel_node])
  File.write!("lib/farmbot/celery_script/ast/node/#{node["name"]}.ex", str)
  # |> Code.eval_string()
end

Farmbot.HTTP.get!("/api/sequences/2").body |> Farmbot.CeleryScript.AST.decode
