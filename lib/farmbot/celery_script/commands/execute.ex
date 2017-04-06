defmodule Farmbot.CeleryScript.Command.Execute do
  @moduledoc """
    Execute
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast

  @behaviour Command

  @doc ~s"""
    executes a thing
      args: %{sequence_id_id: integer}
      body: []
  """
  @spec run(%{sequence_id: integer}, []) :: no_return
  def run(%{sequence_id: id}, []) do
    id
    |> Farmbot.Sync.get_sequence
    |> Ast.parse
    |> Command.do_command
  end
end
