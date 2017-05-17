defmodule Farmbot.CeleryScript.Command.Zero do
  @moduledoc """
    Zero
  """
  alias Farmbot.CeleryScript.{Command, Ast}
  alias Farmbot.Serial.Handler, as: UartHan
  require Logger
  @behaviour Command

  @doc ~s"""
    Set axis current position to "0":
      args: %{axis: "x" | "y" | "z" | "all"}
      body: []
  """
  @spec run(%{axis: String.t}, [], Ast.context) :: Ast.context
  def run(%{axis: axis}, [], context) do
    do_write(axis)
    context
  end

  @spec do_write(binary) :: no_return
  defp do_write("x"), do: "F84 X1 Y0 Z0" |> UartHan.write
  defp do_write("y"), do: "F84 X0 Y1 Z0" |> UartHan.write
  defp do_write("z"), do: "F84 X0 Y0 Z1" |> UartHan.write
end
