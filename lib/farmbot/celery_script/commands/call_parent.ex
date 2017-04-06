defmodule Farmbot.CeleryScript.Command.CallParent do
  @moduledoc """
    CallParent
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast

  @behaviour Command

  @doc ~s"""
  """
  @spec run(%{context: map}, []) :: no_return
  def run(%{context: context}, []) do
    IO.warn "HEY!!! #{inspect context}"
  end
end
