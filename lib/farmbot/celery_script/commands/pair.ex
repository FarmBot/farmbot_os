defmodule Farmbot.CeleryScript.Command.Pair do
  @moduledoc """
    Pair
  """
  alias      Farmbot.CeleryScript.{Ast, Command}
  @behaviour Command

  @doc ~s"""
    Create a Pair object
      args: %{label: String.t, value: any},
      body: []
  """
  @spec run(%{label: String.t, value: any}, [], Context.t) :: Context.t
  def run(%{label: label, value: value}, [], context) do
    data = %Ast{ kind: "pair",
                 args: %{label: label, value: value},
                 body: [] }
    Farmbot.Context.push_data(context, data)
  end
end
