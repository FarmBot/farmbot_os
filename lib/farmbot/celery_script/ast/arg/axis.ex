defmodule Farmbot.CeleryScript.AST.Arg.Axis do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode("x"),   do: {:ok, :x}
  def decode("y"),   do: {:ok, :y}
  def decode("z"),   do: {:ok, :z}
  def decode("all"), do: {:ok, :all}

  def encode(:x),   do: {:ok, "x"}
  def encode(:y),   do: {:ok, "y"}
  def encode(:z),   do: {:ok, "z"}
  def encode(:all), do: {:ok, "all"}
end
