defmodule Farmbot.CeleryScript.Command.Sync do
  @moduledoc """
    Sync
  """

  alias      Farmbot.CeleryScript.Command
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    Do a Sync
      args: %{},
      body: []
  """
  @spec run(%{optional(:package) => binary}, [], Context.t) :: Context.t
  def run(%{package: resource}, [], context) do

  end
  
  def run(%{}, [], context) do
    :ok = Farmbot.Database.sync(context)
    context
  end
end
