defmodule Farmbot.CeleryScript.AST.Arg.Value do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(val), do: {:ok, val}
end
