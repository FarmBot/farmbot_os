defmodule Farmbot.CeleryScript.AST.Node.WritePin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:pin_number, :pin_value, :pin_mode]
end
