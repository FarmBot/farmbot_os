defmodule Farmbot.CeleryScript.Command.InstallFarmware do
  @moduledoc """
    Install Farmware
  """

  # alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Install a farmware
      args: %{url: String.t},
      body: []
  """
  @spec run(%{url: String.t}, [], Ast.context) :: Ast.context
  def run(%{url: url}, [], context) do
    Farmware.install(context, url)
    context
  end
end
