defmodule Farmbot.CeleryScript.AST.Node.NamedPin do
  @moduledoc false

  use Farmbot.CeleryScript.AST.Node
  allow_args [:pin_type, :pin_id]
  return_self()
end
