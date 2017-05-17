defmodule Farmbot.CeleryScript.Command.MoveRelative do
  @moduledoc """
    MoveRel
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast

  @behaviour Command
  @type x :: Command.Coordinate.x
  @type y :: Command.Coordinate.y
  @type z :: Command.Coordinate.z

  @doc ~s"""
    move_relative to a location
      args: %{speed: number, x: number, y: number, z: number}
      body: []
  """
  @spec run(%{speed: number, x: x, y: y, z: z}, [], Ast.context)
    :: Ast.context
  def run(%{speed: speed, x: x, y: y, z: z}, [], context) do
    # make a coordinate of the relative movement we want to do
    new_context = Command.coordinate(%{x: x, y: y, z: z}, [], context)
    {location, new_context} = Ast.Context.pop_data(context)

    # get the current position, then turn it into another coord.
    [cur_x,cur_y,cur_z] = Farmbot.BotState.get_current_pos()

    # Make another coord for the offset
    new_context = Command.coordinate(%{x: cur_x, y: cur_y, z: cur_z}, [], new_context)
    {offset, new_context} = Ast.Context.pop_data(context)

    args = %{speed: speed, offset: offset, location: location}
    Command.move_absolute(args, [], new_context)
  end
end
