defmodule Farmbot.CeleryScript.Command.Wait do
  @moduledoc """
    Wait
  """

  alias      Farmbot.CeleryScript.Command
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    sleeps for a number of milliseconds
      args: %{milliseconds: integer},
      body: []
  """
  @spec run(%{milliseconds: integer}, [], Context.t) :: Context.t
  def run(%{milliseconds: millis}, [], context) do
    Process.sleep(millis)
    context
  end
end
