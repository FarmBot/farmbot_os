defmodule Farmbot.CeleryScript.AST.Arg.Op do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify("is_undefined"), do: {:ok, :is_undefined}
  def verify("is"),           do: {:ok, :==}
  def verify("not"),          do: {:ok, :!=}
  def verify(">"),            do: {:ok, :>}
  def verify("<"),            do: {:ok, :<}
  def verify(other), do: {:error, "unexpected if operator: #{inspect other}"}
end
