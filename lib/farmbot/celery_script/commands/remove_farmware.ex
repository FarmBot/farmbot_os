defmodule Farmbot.CeleryScript.Command.RemoveFarmware do
  @moduledoc """
    Uninstall Farmware
  """

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Uninstall a farmware
      args: %{package: String.t},
      body: []
  """
  @spec run(%{package: String.t}, [], Ast.context) :: Ast.context
  def run(%{package: package}, [], context) do
    Farmware.uninstall(package)
    context
  end
end
