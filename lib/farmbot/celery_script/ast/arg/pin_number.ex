defmodule Farmbot.CeleryScript.AST.Arg.PinNumber do
  @moduledoc false
  alias Farmbot.CeleryScript.AST
  @behaviour AST.Arg
  def decode(val) when is_map(val), do: AST.decode(val)
  def decode(val), do: {:ok, val}
  def encode(%AST{} = ast), do: AST.encode(ast)
  def encode(val), do: {:ok, val}
end
