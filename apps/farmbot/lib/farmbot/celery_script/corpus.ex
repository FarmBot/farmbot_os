defmodule CeleryScript.Command do
  @moduledoc """
    Actionable CeleryScript Commands.
  """
  use CeleryScript.CommandBuilder
  require Logger
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.Serial.Gcode.Parser, as: GcodeParser
  alias Farmbot.Serial.Gcode.Handler, as: GcodeHandler

  @doc """
    requires a location: "coordinate"
  """
  command "move_absolute",
    %{location: %Ast{kind: "coordinate", args: %{x: x, y: y, z: z, s: s}, body: []}} do
    GcodeHandler.block_send("G00 X#{x} Y#{y} Z#{z} S#{s}")
  end

  @doc """
    Executes an ast node.
  """
  def do_command(%Ast{} = ast) do
    Logger.debug ">> is doing #{ast.kind}"
    # i wish there was a better way to do this?
    Kernel.apply(__MODULE__, String.to_atom(ast.kind), [ast.args, ast.body])
    Logger.debug ">> is finished with #{ast.kind}"
  end


end
