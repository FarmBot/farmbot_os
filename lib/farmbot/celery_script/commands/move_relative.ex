defmodule Farmbot.CeleryScript.Command.MoveRelative do
  @moduledoc """
    MoveRel
  """

  alias Farmbot.CeleryScript.Command

  @behaviour Command
  @type x :: Command.Coordinate.x
  @type y :: Command.Coordinate.y
  @type z :: Command.Coordinate.z

  @doc ~s"""
    move_relative to a location
      args: %{speed: number, x: number, y: number, z: number}
      body: []
  """
  @spec run(%{speed: number, x: x, y: y, z: z}, [], Context.t)
    :: Context.t

  def run(%{speed: speed, x: x, y: y, z: z}, [], context) do
    # make a coordinate of the relative movement we want to do
    loc                      = %{x: x, y: y, z: z}
    new_context1             = Command.coordinate(loc, [], context)
    {location, new_context2} = Farmbot.Context.pop_data(new_context1)

    # get the current position, then turn it into another coord.
    [cur_x,cur_y,cur_z]      = Farmbot.BotState.get_current_pos(context)

    # Make another coord for the offset
    coord_args               = %{x: cur_x, y: cur_y, z: cur_z}
    new_context3             = Command.coordinate(coord_args, [], new_context2)
    {offset, new_context4}   = Farmbot.Context.pop_data(new_context3)

    args = %{speed: speed, offset: offset, location: location}
    Command.move_absolute(args, [], new_context4)
  end
end
