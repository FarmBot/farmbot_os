defmodule Farmbot.CeleryScript.AST.Arg.SequenceId do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(_), do: :ok
end
