defmodule Farmbot.CeleryScript.Command.Sync do
  @moduledoc """
    Sync
  """

  alias      Farmbot.CeleryScript.{Ast, Command}
  alias      Farmbot.{Context, Database}
  @behaviour Command

  @doc ~s"""
    Do a Sync
      args: %{},
      body: []
  """
  def run(_, _, context) do
    :ok = Database.sync(context)
    context
  end
end
