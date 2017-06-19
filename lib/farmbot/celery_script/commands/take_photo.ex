defmodule Farmbot.CeleryScript.Command.TakePhoto do
  @moduledoc """
    Take a photo
  """

  alias      Farmbot.CeleryScript.{Command, Error}
  alias      Farmbot.{Context, Farmware}
  import     Command, only: [execute_script: 3]
  @behaviour Command

  @doc ~s"""
    Takes a photo
      args: %{},
      body: []
  """
  @spec run(%{}, [], Context.t) :: Context.t
  def run(%{}, [], context) do
    case Farmware.Manager.lookup_by_name(context, "take-photo") do
      {:ok, %Farmware{} = fw} -> execute_script(%{label: fw.uuid}, [], context)
      {:error, e}             -> raise Error, context: context,
        message: "Could not execute take photo: #{inspect e}"
    end
  end
end
