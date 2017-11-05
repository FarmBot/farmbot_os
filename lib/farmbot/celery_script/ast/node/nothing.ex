defmodule Farmbot.CeleryScript.AST.Node.Nothing do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args []

  def execute(_, _, env), do: {:ok, env}
end
