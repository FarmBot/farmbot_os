defmodule Farmbot.CeleryScript.Command.MoveAbsolute do
  @moduledoc """
    Update Farmware
  """

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  alias Farmbot.Lib.Maths
  require Logger
  alias Farmbot.Serial.Gcode.Handler, as: GHan
  # alias Farmbot.Serial.Gcode.Parser, as: GParser
  @behaviour Command

  @type coordinate_ast :: Command.Coordinate.t

  @doc ~s"""
    move_absolute to a prticular position.
      args: %{
        speed: integer,
        offset: coordinate_ast | Ast.t
        location: coordinate_ast | Ast.t
      },
      body: []
  """
  @type move_absolute_args :: %{
    speed: integer,
    offset: coordinate_ast | Ast.t,
    location: coordinate_ast | Ast.t
  }
  @spec run(move_absolute_args, []) :: no_return
  @lint {Credo.Check.Refactor.ABCSize, false}
  def run(%{speed: s, offset: offset, location: location}, []) do
    with %Ast{kind: "coordinate", args: %{x: xa, y: ya, z: za}, body: []} <-
            Command.ast_to_coord(location),
         %Ast{kind: "coordinate", args: %{x: xb, y: yb, z: zb}, body: []} <-
            Command.ast_to_coord(offset)
    do
      [x, y, z] =
        [Maths.mm_to_steps(xa + xb, spm(:x)),
         Maths.mm_to_steps(ya + yb, spm(:y)),
         Maths.mm_to_steps(za + zb, spm(:z))]
      thing = "G00 X#{x} Y#{y} Z#{z} S#{s}" |> GHan.block_send
      Logger.debug ">> Moved to: #{xa + xb}, #{ya + xb}, #{za + xb} " <>
        "[#{inspect thing}]", type: :success
      thing
    else
      _ -> Logger.error ">> error doing Move absolute!"
    end
  end

  defp spm(xyz) do
    "steps_per_mm_#{xyz}"
    |> String.to_atom
    |> Farmbot.BotState.get_config()
  end

end
