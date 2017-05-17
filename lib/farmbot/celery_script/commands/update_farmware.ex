defmodule Farmbot.CeleryScript.Command.UpdateFarmware do
  @moduledoc """
    Update Farmware
  """

  # alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.{Command, Ast}
  require Logger
  @behaviour Command

  @doc ~s"""
    Update a farmware
      args: %{package: String.t},
      body: []
  """
  @spec run(%{package: String.t}, [], Ast.context) :: Ast.context
  def run(%{package: package}, [], context) do
    Farmware.update(package)
    context
  end
end
