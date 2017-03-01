defmodule Farmbot.CeleryScript.Command.RemoveFarmware do
  @moduledoc """
    Uninstall Farmware
  """

  # alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Uninstall a farmware
      args: %{package: String.t},
      body: []
  """
  @spec run(%{package: String.t}, []) :: no_return
  def run(%{package: package}, []) do
    Farmware.uninstall(package)
  end
end
