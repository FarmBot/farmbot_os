defmodule Farmbot.CeleryScript.Command.ReadParam do
  @moduledoc """
    ReadParam
  """

  alias      Farmbot.CeleryScript.Command
  alias      Farmbot.Serial.Handler, as: UartHan
  alias      Farmbot.Serial.Gcode.Parser, as: GParser
  alias      Farmbot.Context
  require    Logger
  @behaviour Command

  @doc ~s"""
    Reads a param value
      args: %{label: binary}
      body: []
  """
  @spec run(%{label: binary}, [], Context.t) :: Context.t
  def run(%{label: param_str}, [], context) do
    param_int = GParser.parse_param(param_str)
    if param_int do
      UartHan.write(context, "F21 P#{param_int}", 1000)
      context
    else
      raise "#{param_str} is not a valid param!"
    end
  end
end
