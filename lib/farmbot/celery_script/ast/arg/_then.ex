defmodule Farmbot.CeleryScript.AST.Arg.Then do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(val), do: {:ok, val}
end
