defmodule Farmbot.CeleryScript.AST.Arg.PinNumber do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(val), do: {:ok, val}
end
