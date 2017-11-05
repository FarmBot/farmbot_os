defmodule Farmbot.CeleryScript.AST.Arg.Rhs do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(val) when is_number(val), do: {:ok, val}
  def verify(val), do: {:error, "unexpected right hand side: #{inspect val}"}
end
