defmodule Farmbot.CeleryScript.AST.Arg.PinNumber do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def verify(_), do: :ok
end
