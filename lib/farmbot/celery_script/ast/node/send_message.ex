defmodule Farmbot.CeleryScript.AST.Node.SendMessage do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:message, :message_type]
end
