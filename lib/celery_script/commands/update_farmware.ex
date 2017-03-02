defmodule Farmbot.CeleryScript.Command.UpdateFarmware do
  @moduledoc """
    Update Farmware
  """

  # alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Update a farmware
      args: %{package: String.t},
      body: []
  """
  @spec run(%{package: String.t}, []) :: no_return
  def run(%{package: package}, []) do
    Farmware.update(package)
  end
end
