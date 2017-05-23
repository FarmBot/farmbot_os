defmodule Farmbot.CeleryScript.Command.ReadStatus do
  @moduledoc """
    ReadStatus
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast
  @behaviour Command

  @doc ~s"""
    Do a ReadStatus
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    Farmbot.Transport.force_state_push(context)
    context
  end
end
