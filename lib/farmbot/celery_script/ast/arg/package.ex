defmodule Farmbot.CeleryScript.AST.Arg.Package do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode("farmbot_os"), do: {:ok, :farmbot_os}
  def decode("arduino_firmware"), do: {:ok, :arduino_firmware}
  def decode(other), do: {:ok, {:farmware, other}}

  def encode(:farmbot_os),          do: {:ok, "farmbot_os"}
  def encode(:arduino_firmware),    do: {:ok, "arduino_firmware"}
  def encode({:farmware, package}), do: {:ok, "package"}
end
