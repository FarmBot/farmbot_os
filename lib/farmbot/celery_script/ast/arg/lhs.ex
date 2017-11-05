defmodule Farmbot.CeleryScript.AST.Arg.Lhs do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify("x"), do: {:ok, :x}
  def verify("y"), do: {:ok, :y}
  def verify("z"), do: {:ok, :z}

  def verify("pin" <> num), do: {:pin, String.to_integer(num)}

  def verify(other), do: {:error, "unknown left hand side: #{inspect other}"}
end
