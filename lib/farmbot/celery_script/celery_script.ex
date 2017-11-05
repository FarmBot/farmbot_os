defmodule Farmbot.CeleryScript do
  @moduledoc """
  CeleryScript is the scripting language that Farmbot OS understands.
  """

  alias Farmbot.CeleryScript.AST

  @doc "Execute an AST node."
  def execute(ast)

  def execute(%AST{} = ast) do
    
  end
end
