defmodule Farmbot.CeleryScript.Command.Home do
  @moduledoc """
    Home
  """

  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast
  @behaviour Command

  @doc ~s"""
    Homes an axis
      args: %{axis: "x" | "y" | "z" | "all"},
      body: []
  """
  @type axis :: String.t # "x" | "y" | "z" | "all"
  @spec run(%{axis: axis}, [], Ast.context) :: Ast.context
  def run(%{axis: "all"}, [], context) do
    run(%{axis: "z"}, [], context) # <= Home z FIRST to prevent plant damage
    run(%{axis: "y"}, [], context)
    run(%{axis: "x"}, [], context)
    context
  end

  def run(%{axis: axis}, [], context)
  when is_bitstring(axis) do
    [cur_x, cur_y, cur_z] = Farmbot.BotState.get_current_pos
    speed = 100
    {blah, next_context1} = Command.nothing(%{}, [], context)
    next_context2 =
      %{x: cur_x, y: cur_y, z: cur_z}
      |> Map.put(String.to_atom(axis), 0)
      |> Command.coordinate([], next_context1)
    {location, next_context3} = Ast.Context.pop_data(next_context2)
    Command.move_absolute(%{speed: speed, location: location, offset: blah},
                          [],
                          next_context3)
  end
end
