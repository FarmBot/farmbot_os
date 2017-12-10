defmodule Farmbot.CeleryScript.AST.Node.Channel do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:channel_name]

  return_self()
end
