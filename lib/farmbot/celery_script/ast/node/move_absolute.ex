defmodule Farmbot.CeleryScript.AST.Node.MoveAbsolute do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:location, :speed, :offset]
end
