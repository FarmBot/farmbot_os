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
  def run(%{sequence_id: id} = args, []) do
    id
    |> Farmbot.Sync.get_sequence
    |> Ast.parse
    |> merge_args(args)
    |> delete_me()
    |> Command.do_command
  end

  defp merge_args(ast, args), do: %{ast | args: Map.merge(ast.args, args)}

  defp delete_me(ast) do
    %{ast | body: [blerp() | ast.body]}
  end

  defp blerp do
    %Farmbot.CeleryScript.Ast{args: %{}, body: [], comment: nil, kind: "ping_parent"}
  end
end
