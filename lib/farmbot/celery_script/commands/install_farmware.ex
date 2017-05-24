defmodule Farmbot.CeleryScript.Command.InstallFarmware do
  @moduledoc """
    Install Farmware
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    Install a farmware
      args: %{url: String.t},
      body: []
  """
  @spec run(%{url: String.t}, [], Ast.context) :: Ast.context
  def run(%{url: url}, [], context) do
    Farmbot.Farmware.Manager.install!(context, url)
    context
  end
end
