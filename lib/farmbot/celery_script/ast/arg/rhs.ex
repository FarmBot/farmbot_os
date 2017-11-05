defmodule Farmbot.CeleryScript.AST.Arg.Rhs do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(val) when is_number(val), do: {:ok, val}
  def decode(val), do: {:error, "unexpected right hand side: #{inspect val}"}

  def encode(val), do: {:ok, val}
end
