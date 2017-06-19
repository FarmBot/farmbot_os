defmodule Farmbot.CeleryScript.Command.Execute do
  @moduledoc """
    Execute
  """

  alias Farmbot.CeleryScript.{Ast, Command, Error}
  alias Farmbot.Database.Syncable.Sequence

  @behaviour Command

  @doc ~s"""
    executes a thing
      args: %{sequence_id_id: integer}
      body: []
  """
  @spec run(%{sequence_id: integer}, [], Context.t) :: Context.t
  def run(%{sequence_id: id}, [], context) do
    sequence = Farmbot.Database.get_by_id(context, Sequence, id)
    unless sequence do
      raise Error, context: context,
        message: "Could not find sequence by id: #{id}"
    end

    sequence.body
    |> Ast.parse()
    |> Command.do_command(context)
  end
end
