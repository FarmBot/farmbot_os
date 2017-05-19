defmodule Farmbot.CeleryScript.Command.Wait do
  @moduledoc """
    Wait
  """

  alias Farmbot.CeleryScript.{Command, Ast}

  @behaviour Command

  @doc ~s"""
    sleeps for a number of milliseconds
      args: %{milliseconds: integer},
      body: []
  """
  @spec run(%{milliseconds: integer}, [], Ast.context) :: Ast.context
  def run(%{milliseconds: millis}, [], context) do
    Process.sleep(millis)
    context
  end
end
