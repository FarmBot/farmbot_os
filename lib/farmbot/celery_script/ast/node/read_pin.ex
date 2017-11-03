defmodule Farmbot.CeleryScript.AST.Node.ReadPin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:pin_number, :label, :pin_mode]
end
