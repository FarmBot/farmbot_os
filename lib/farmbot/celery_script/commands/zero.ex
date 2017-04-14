defmodule Farmbot.CeleryScript.Command.Zero do
  @moduledoc """
    Zero
  """
  alias Farmbot.Serial.Handler, as: UartHan
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Set axis current position to "0":
      args: %{axis: "x" | "y" | "z" | "all"}
      body: []
  """
  @spec run(%{axis: String.t}, []) :: no_return
  def run(%{axis: axis}, []), do: do_write(axis)

  @spec do_write(binary) :: no_return
  defp do_write("x"), do:"F84 X1 Y0 Z0" |>  UartHan.write
  defp do_write("y"), do:"F84 X0 Y1 Z0" |>  UartHan.write
  defp do_write("z"), do:"F84 X0 Y0 Z1" |>  UartHan.write
end
