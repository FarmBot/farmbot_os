defmodule Farmbot.CeleryScript.Command.Calibrate do
  @moduledoc """
    Calibrate
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.Serial.Handler, as: UartHan
  @behaviour Command

  @doc ~s"""
    calibrates an axis:
      args: %{axis: "x" | "y" | "z"}
      body: []
  """
  @spec run(%{axis: String.t}, [], Ast.context) :: Ast.context
  def run(%{axis: axis}, [], context) do
    do_write(axis)
    context
  end

  @spec do_write(binary) :: no_return
  defp do_write("x"), do: UartHan.write "F14"
  defp do_write("y"), do: UartHan.write "F15"
  defp do_write("z"), do: UartHan.write "F16"
end
