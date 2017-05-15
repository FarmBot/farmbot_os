defmodule Farmbot.CeleryScript.Command.Sync do
  @moduledoc """
    Sync
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    Do a Sync
      args: %{},
      body: []
  """
  @spec run(%{}, []) :: no_return
  def run(%{}, []) do
    Farmbot.Database.sync()
  end
end
