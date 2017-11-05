defmodule Farmbot.CeleryScript.AST.Arg.Lhs do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode("x"), do: {:ok, :x}
  def decode("y"), do: {:ok, :y}
  def decode("z"), do: {:ok, :z}

  def decode("pin" <> num), do: {:pin, String.to_integer(num)}

  def decode(other), do: {:error, "unknown left hand side: #{inspect other}"}

  def encode(:x), do: {:ok, "x"}
  def encode(:y), do: {:ok, "y"}
  def encode(:z), do: {:ok, "z"}
  def encode({:pin, num}), do: {:ok, "pin#{num}"}
end
