defmodule Farmbot.CeleryScript.AST.Node.ReadStatus do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  def execute(_, _, env) do
    Farmbot.BotState.force_state_push()
    {:ok, env}
  end
end
