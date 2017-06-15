defmodule Farmbot.CeleryScript.Command.Zero do
  @moduledoc """
    Zero
  """
  alias      Farmbot.CeleryScript.{Command, Types}
  alias      Farmbot.Serial.Handler, as: UartHan
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    Set axis current position to "0":
      args: %{axis: "x" | "y" | "z" | "all"}
      body: []
  """
  @spec run(%{axis: Types.axis}, [], Context.t) :: Context.t
  def run(%{axis: axis}, [], context) do
    do_write(axis, context)
    context
  end

  @spec do_write(binary, Context.t) :: no_return
  defp do_write("x", ctx), do: UartHan.write(ctx, "F84 X1 Y0 Z0")
  defp do_write("y", ctx), do: UartHan.write(ctx, "F84 X0 Y1 Z0")
  defp do_write("z", ctx), do: UartHan.write(ctx, "F84 X0 Y0 Z1")
end
