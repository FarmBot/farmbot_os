defmodule Farmbot.CeleryScript.Command.Home do
  @moduledoc """
    Home
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
    Homes an axis
      args: %{axis: "x" | "y" | "z" | "all"},
      body: []
  """
  @type axis :: String.t # "x" | "y" | "z" | "all"
  @spec run(%{axis: axis}, [], Context.t) :: Context.t
  def run(%{axis: "all"}, [], context) do
    run(%{axis: "z"}, [], context) # <= Home z FIRST to prevent plant damage
    run(%{axis: "y"}, [], context)
    run(%{axis: "x"}, [], context)
    context
  end

  def run(%{axis: axis}, [], context)
  when is_bitstring(axis) do
    [cur_x, cur_y, cur_z] = Farmbot.BotState.get_current_pos(context)
    speed = 100

    next_context1 = Command.nothing(%{}, [], context)
    {blah, next_context2} = Farmbot.Context.pop_data(next_context1)

    args = Map.put(%{x: cur_x, y: cur_y, z: cur_z}, String.to_atom(axis), 0)
    next_context3 = Command.coordinate(args, [], next_context2)
    {location, next_context4} = Farmbot.Context.pop_data(next_context3)
    Command.move_absolute(%{speed: speed, location: location, offset: blah},
                          [],
                          next_context4)
  end
end
