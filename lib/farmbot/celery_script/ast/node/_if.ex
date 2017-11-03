defmodule Farmbot.CeleryScript.AST.Node.If do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:lhs, :op, :rhs, :_then, :_else]
end
