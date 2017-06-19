defmodule Farmbot.CeleryScript.Command.UpdateFarmware do
  @moduledoc """
    Update Farmware
  """

  alias      Farmbot.CeleryScript.{Command, Types}
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    Update a farmware
      args: %{package: String.t},
      body: []
  """
  @spec run(%{package: Types.package}, [], Context.t) :: Context.t
  def run(%{package: uuid}, [], context) do
    Farmbot.Farmware.Manager.update!(context, uuid)
    context
  end
end
