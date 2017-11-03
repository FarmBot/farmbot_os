defmodule Farmbot.CeleryScript.AST.Arg.Else do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(val), do: Farmbot.CeleryScript.AST.decode(val)
end
