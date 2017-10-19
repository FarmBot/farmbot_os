defmodule Farmbot.CeleryScript.Command.Calibrate do
  @moduledoc """
    Calibrate
  """

  alias Farmbot.CeleryScript.{Command, Types}
  alias Farmbot.Serial.Handler, as: UartHan
  require Logger
  @behaviour Command

  @doc ~s"""
    calibrates an axis:
      args: %{axis: "x" | "y" | "z"}
      body: []
  """
  @spec run(%{axis: Types.axis}, [], Context.t) :: Context.t
  def run(%{axis: "all"}, [], context) do
    for axis <- ["x", "y", "z"] do
      run(%{axis: axis}, [], context)
    end
    context
  end

  def run(%{axis: axis}, [], context) do
    Logger.debug "Begin calibration on axis: #{axis}", type: :busy
    do_write(axis, context)
    Logger.debug "Calibration complete on axis: #{axis}", type: :success
    context
  end

  @spec do_write(binary, Context.t) :: no_return
  defp do_write("x", context), do: UartHan.write(context, "F14")
  defp do_write("y", context), do: UartHan.write(context, "F15")
  defp do_write("z", context), do: UartHan.write(context, "F16")
end
