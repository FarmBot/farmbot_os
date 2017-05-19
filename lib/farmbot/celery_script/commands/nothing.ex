defmodule Farmbot.CeleryScript.Command.Nothing do
  @moduledoc """
    Nothing
  """

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    does absolutely nothing.
      args: %{},
      body: []
  """
  @type nothing_ast :: %Ast{kind: String.t, args: %{}, body: []}
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(args, body, context) do
    thing = %Ast{kind: "nothing", args: args, body: body}
    Farmbot.Context.push_data(context, thing)
  end
end
