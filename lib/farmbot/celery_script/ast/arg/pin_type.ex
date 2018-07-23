defmodule Farmbot.CeleryScript.AST.Arg.PinType do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg
  alias Farmbot.Asset.{Peripheral, Sensor}

  def decode("Peripheral"), do: {:ok, Peripheral}
  def decode("Sensor"),     do: {:ok, Sensor}
  def decode("BoxLed3"),    do: {:ok, "BoxLed3"}
  def decode("BoxLed4"),    do: {:ok, "BoxLed4"}

  def encode(Peripheral),   do: {:ok, "Peripheral"}
  def encode(Sensor),       do: {:ok, "Sensor"}
end
