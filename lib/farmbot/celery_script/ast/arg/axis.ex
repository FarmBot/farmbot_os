defmodule Farmbot.CeleryScript.AST.Arg.Axis do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify("x"), do: {:ok, :x}
  def verify("y"), do: {:ok, :y}
  def verify("z"), do: {:ok, :z}
  def verify("all"), do: {:ok, :all}
end
