defmodule Farmbot.CeleryScript.AST.Arg.Label do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(val), do: {:ok, val}
end
