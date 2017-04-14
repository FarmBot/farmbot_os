defmodule Farmbot.CeleryScript.Command.Zero do
  @moduledoc """
    Zero
  """

  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Set axis current position to "0":
      args: %{axis: "x" | "y" | "z" | "all"}
      body: []
  """
  @spec run(%{axis: String.t}, []) :: no_return
  @lint {Credo.Check.Refactor.PipeChainStart, false}
  def run(%{axis: axis}, []) do
    case axis do
      "x" -> "F84 X1 Y0 Z0"
      "y" -> "F84 X0 Y1 Z0"
      "z" -> "F84 X0 Y0 Z1"
    end |> UartHan.write
  end
end
