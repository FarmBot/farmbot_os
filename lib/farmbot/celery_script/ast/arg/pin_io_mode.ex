defmodule Farmbot.CeleryScript.AST.Arg.PinIoMode do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(0x0), do: :input
  def decode(0x2), do: :input_pullup
  def decode(0x1), do: :output

  def encode(:input), do: 0x0
  def encode(:input_pullup), do: 0x2
  def encode(:output), do: 0x1
end
