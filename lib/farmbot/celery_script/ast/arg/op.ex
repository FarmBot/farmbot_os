defmodule Farmbot.CeleryScript.AST.Arg.Op do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode("is_undefined"), do: {:ok, :is_undefined}
  def decode("is"),           do: {:ok, :==}
  def decode("not"),          do: {:ok, :!=}
  def decode(">"),            do: {:ok, :>}
  def decode("<"),            do: {:ok, :<}
  def decode(other), do: {:error, "unexpected if operator: #{inspect other}"}

  def encode(:is_undefined), do: {:ok, "is_undefined"}
  def encode(:==), do: {:ok, "is"}
  def encode(:!=), do: {:ok, "not"}
  def encode(:>),  do: {:ok, ">"}
  def encode(:<),  do: {:ok, "<"}
end
