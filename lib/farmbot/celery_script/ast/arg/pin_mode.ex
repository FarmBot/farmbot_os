defmodule Farmbot.CeleryScript.AST.Arg.PinMode do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(0), do: {:ok, :digital}
  def decode(1), do: {:ok, :analog}
  
  def encode(:digital), do: {:ok, 0}
  def encode(:analog),  do: {:ok, 1}
end
