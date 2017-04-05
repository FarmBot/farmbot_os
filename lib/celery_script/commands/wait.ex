defmodule Farmbot.CeleryScript.Command.Wait do
  @moduledoc """
    Wait
  """

  alias Farmbot.CeleryScript.Command

  @behaviour Command

  @doc ~s"""
    sleeps for a number of milliseconds
      args: %{milliseconds: integer},
      body: []
  """
  @spec run(%{milliseconds: integer}, []) :: no_return
  def run(%{milliseconds: millis}, []), do: Process.sleep(millis)
end
