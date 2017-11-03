defmodule Farmbot.CeleryScript.AST.Node.MoveRelative do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:x, :y, :z, :speed]
end
