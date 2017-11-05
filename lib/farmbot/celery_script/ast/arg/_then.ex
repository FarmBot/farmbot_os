defmodule Farmbot.CeleryScript.AST.Arg.Then do
  @moduledoc false
  @behaviour Farmbot.CeleryScript.AST.Arg

  def decode(val), do: Farmbot.CeleryScript.AST.decode(val)

  def encode(ast), do: Farmbot.CeleryScript.AST.encode(ast) 
end
