defmodule Farmbot.CeleryScript.Command.Explanation do
  @moduledoc """
    Explanation
  """

  alias Farmbot.CeleryScript.{Command, Ast}
  @behaviour Command

  @doc ~s"""
    Explanation for an rpc error
      args: %{label: String.t},
      body: []
  """
  @spec run(%{message: binary}, [], Context.t) :: Context.t
  def run(%{message: message}, [], context) do
    result = %Ast{kind: "explanation", args: %{message: message}, body: []}
    Farmbot.Context.push_data(context, result)
  end
end
