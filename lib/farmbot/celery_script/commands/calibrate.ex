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
  @spec run(%{axis: String.t}, [], Context.t) :: Context.t
  def run(%{axis: axis}, [], context) do
    do_write(axis, context)
    context
  end

  @spec do_write(binary, Context.t) :: no_return
  defp do_write("x", context), do: UartHan.write(context, "F14")
  defp do_write("y", context), do: UartHan.write(context, "F15")
  defp do_write("z", context), do: UartHan.write(context, "F16")
end
