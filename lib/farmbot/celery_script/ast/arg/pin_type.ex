defmodule Farmbot.CeleryScript.AST.Arg.PinType do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg
  alias Farmbot.Asset.{Peripheral, Sensor}

  def decode("Peripheral"), do: {:ok, Peripheral}
  def decode("Sensor"),     do: {:ok, Sensor}

  def encode(Peripheral),   do: {:ok, "Peripheral"}
  def encode(Sensor),       do: {:ok, "Sensor"}
end
