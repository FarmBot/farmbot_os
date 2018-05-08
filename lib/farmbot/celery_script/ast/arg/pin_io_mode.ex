defmodule Farmbot.CeleryScript.AST.Arg.PinIoMode do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(0x0), do: {:ok, :input}
  def decode(0x2), do: {:ok, :input_pullup}
  def decode(0x1), do: {:ok, :output}

  def encode(:input), do: {:ok, 0x0}
  def encode(:input_pullup), do: {:ok, 0x2}
  def encode(:output), do: {:ok, 0x1}
end
