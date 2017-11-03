defmodule Farmbot.CeleryScript.AST.Arg.Milliseconds do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(val), do: {:ok, val}
end
