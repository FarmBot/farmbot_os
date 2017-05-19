defmodule Farmbot.CeleryScript.Command.Sync do
  @moduledoc """
    Sync
  """

  alias Farmbot.CeleryScript.{Command, Ast}
  @behaviour Command

  @doc ~s"""
    Do a Sync
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    Farmbot.Database.sync(context)
    context
  end
end
