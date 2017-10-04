defmodule Farmbot.CeleryScript.Command.MoveAbsolute do
  @moduledoc """
    Update Farmware
  """

  alias      Farmbot.CeleryScript.{Command, Types, Error}
  import     Command, only: [ast_to_coord: 2]
  require    Logger
  alias      Farmbot.Serial.Handler, as: UartHan
  alias      Farmbot.Context
  @behaviour Command

  @type coordinate_ast :: Types.coord_ast

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
    offset: coordinate_ast   | Types.ast,
    location: coordinate_ast | Types.ast
  }
  @spec run(move_absolute_args, [], Context.t) :: Context.t
  def run(%{speed: speed, offset: offset, location: location}, _, ctx) do
    case UartHan.wait_for_available(ctx) do
      {:error, reason} -> raise Error, "Failed to start movement: #{inspect reason}"
      _ -> :noop
    end

    Logger.info ">> Doing movement.", type: :busy
    new_context              = ast_to_coord(ctx, location)
    {location, new_context1} = Farmbot.Context.pop_data(new_context)

    new_context2             = ast_to_coord(new_context1, offset)
    {offset, new_context3}   = Farmbot.Context.pop_data(new_context2)

    {xa, ya, za} = {location.args.x, location.args.y, location.args.z}
    {xb, yb, zb} = {offset.args.x,   offset.args.y,    offset.args.z }
    { combined_x, combined_y, combined_z } = { xa + xb, ya + yb, za + zb }
    {x, y, z} = {combined_x, combined_y, combined_z}
    case UartHan.write(new_context3, "G00 X#{x} Y#{y} Z#{z} S#{speed}", 10_000) do
      {:error, reason} -> raise Error, "Movement failed: #{reason}"
      _ ->
        Logger.info ">> Movement complete.", type: :success
        new_context3
    end
  end
end
