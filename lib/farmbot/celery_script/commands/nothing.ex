defmodule Farmbot.CeleryScript.Command.Nothing do
  @moduledoc """
    Nothing
  """

  alias      Farmbot.CeleryScript.{Ast, Command}
  @behaviour Command

  @doc ~s"""
    does absolutely nothing.
      args: %{},
      body: []
  """

  @spec run(%{}, [], Context.t) :: Context.t
  def run(args, body, context) do
    thing = %Ast{kind: "nothing", args: args, body: body}
    Farmbot.Context.push_data(context, thing)
  end
end
