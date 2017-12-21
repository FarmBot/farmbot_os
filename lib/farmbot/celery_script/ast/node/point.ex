defmodule Farmbot.CeleryScript.AST.Node.Point do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:pointer_type, :pointer_id]

  return_self()
end
