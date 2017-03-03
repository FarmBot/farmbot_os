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
  @spec run(%{}, []) :: nothing_ast
  def run(args, body), do: %Ast{kind: "nothing", args: args, body: body}
end
