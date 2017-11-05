defmodule Farmbot.CeleryScript.AST.Arg.Package do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify("farmbot_os"), do: {:ok, :farmbot_os}
  def verify("arduino_firmware"), do: {:ok, :arduino_firmware}
  def verify(other), do: {:ok, {:farmware, other}}
end
