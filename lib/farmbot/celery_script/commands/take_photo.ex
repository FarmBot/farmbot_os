defmodule Farmbot.CeleryScript.Command.TakePhoto do
  @moduledoc """
    Take a photo
  """

  alias Farmbot.CeleryScript.{Command, Ast}
  alias Farmbot.Farmware
  @behaviour Command

  @doc ~s"""
    Takes a photo
      args: %{},
      body: []
  """
  @spec run(%{}, [], Ast.context) :: Ast.context
  def run(%{}, [], context) do
    case Farmware.Manager.lookup_by_name(context, "take-photo") do
      {:ok, %Farmware{} = fw} -> Farmware.Runtime.execute(context, fw)
      {:error, e} -> raise "Could not execute take photo: #{inspect e}"
    end
  end
end
