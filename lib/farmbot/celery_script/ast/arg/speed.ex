defmodule Farmbot.CeleryScript.AST.Arg.Speed do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(val), do: {:ok, val}
end
