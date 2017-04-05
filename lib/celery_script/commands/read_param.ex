defmodule Farmbot.CeleryScript.Command.ReadParam do
  @moduledoc """
    ReadParam
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.Serial.Handler, as: UartHan
  alias Farmbot.Serial.Gcode.Parser, as: GParser
  @behaviour Command
  require Logger

  @doc ~s"""
    Reads a param value
      args: %{label: String.t}
      body: []
  """
  @spec run(%{label: String.t}, []) :: no_return
  def run(%{label: param_str}, []) do
    param_int = GParser.parse_param(param_str)
    if param_int do
      UartHan.write("F21 P#{param_int}", 1000)
    else
      Logger.error ">> got unknown param: #{param_str}"
    end
  end
end
