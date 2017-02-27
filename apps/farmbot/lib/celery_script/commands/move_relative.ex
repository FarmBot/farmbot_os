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
  @spec run(%{speed: number, x: x, y: y, z: z}, [])
    :: no_return
  def run(%{speed: speed, x: x, y: y, z: z}, []) do
    # make a coordinate of the relative movement we want to do
    location = Command.coordinate(%{x: x, y: y, z: z}, [])

    # get the current position, then turn it into another coord.
    [cur_x,cur_y,cur_z] = Farmbot.BotState.get_current_pos
    offset = Command.coordinate(%{x: cur_x, y: cur_y, z: cur_z}, [])
    %{speed: speed, offset: offset, location: location}
    |> Command.move_absolute([])
  end
end
