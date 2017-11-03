defmodule Farmbot.CeleryScript.AST.Arg.Z do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(val), do: {:ok, val}
end
