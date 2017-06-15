defmodule Farmbot.CeleryScript.Command.RemoveFarmware do
  @moduledoc """
    Uninstall Farmware
  """

  alias      Farmbot.CeleryScript.Command
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    Uninstall a farmware
      args: %{package: uuid},
      body: []
  """
  @spec run(%{package: binary}, [], Context.t) :: Context.t
  def run(%{package: uuid}, [], context) do
    Farmbot.Farmware.Manager.uninstall!(context, uuid)
    context
  end
end
