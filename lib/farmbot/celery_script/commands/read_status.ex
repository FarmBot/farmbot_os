defmodule Farmbot.CeleryScript.Command.ReadStatus do
  @moduledoc """
    ReadStatus
  """

  alias      Farmbot.CeleryScript.Command
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    Do a ReadStatus
      args: %{},
      body: []
  """
  @spec run(%{}, [], Context.t) :: Context.t
  def run(%{}, [], context) do
    Farmbot.Transport.force_state_push(context)
    context
  end
end
