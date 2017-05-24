defmodule Farmbot.CeleryScript.Command.UpdateFarmware do
  @moduledoc """
    Update Farmware
  """

  alias Farmbot.CeleryScript.{Command, Ast}
  @behaviour Command

  @doc ~s"""
    Update a farmware
      args: %{package: String.t},
      body: []
  """
  @spec run(%{package: String.t}, [], Ast.context) :: Ast.context
  def run(%{package: uuid}, [], context) do
    Farmbot.Farmware.Manager.update!(context, uuid)
    context
  end
end
