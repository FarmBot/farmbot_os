defmodule Farmbot.CeleryScript.Command do
  @moduledoc """
    Actionable CeleryScript Commands.
  """
  use CeleryScript.CommandBuilder
  require Logger
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.Serial.Gcode.Parser, as: GcodeParser
  alias Farmbot.Serial.Gcode.Handler, as: GcodeHandler

  @doc """
    requires a location: "coordinate" and an offset "coordinate" or "nothing"
  """
  command "move_absolute",
    %{
      location: %Ast{kind: "coordinate", args: %{x: x, y: y, z: z}, body: []},
      offset:   %Ast{kind: "coordinate", args: %{x: xa, y: ya, z: za}, body: []},
      speed: s
     }
  do
    GcodeHandler.block_send("G00 X#{x + xa} Y#{y + xa} Z#{z + za} S#{s}")
  end

  command "move_absolute",
    %{
      location: %Ast{kind: "coordinate", args: %{x: x, y: y, z: z}, body: []},
      offset:   %Ast{kind: "nothing", args: %{}, body: []},
      speed: s
     }
  do
    GcodeHandler.block_send("G00 X#{x} Y#{y} Z#{z} S#{s}")
  end

  @doc """
    Executes an ast node.
  """
  def do_command(%Ast{} = ast) do
    Logger.debug ">> is doing #{ast.kind}"
    # i wish there was a better way to do this?
    f = Kernel.apply(__MODULE__, String.to_atom(ast.kind), [ast.args, ast.body])
    Logger.debug ">> is finished with #{ast.kind}"
    f
  end


end
