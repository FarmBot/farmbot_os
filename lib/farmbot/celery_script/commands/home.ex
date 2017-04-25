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
  @spec run(%{axis: axis}, []) :: no_return
  def run(%{axis: "all"}, []) do
    run(%{axis: "z"}, []) # <= Home z FIRST to prevent plant damage
    run(%{axis: "y"}, [])
    run(%{axis: "x"}, [])
  end

  def run(%{axis: axis}, [])
  when is_bitstring(axis) do
    [cur_x, cur_y, cur_z] = Farmbot.BotState.get_current_pos
    speed = 100
    blah = Command.nothing(%{}, [])
    location =
      %{x: cur_x, y: cur_y, z: cur_z}
      |> Map.put(String.to_atom(axis), 0)
      |> Command.coordinate([])
    Command.move_absolute(%{speed: speed, location: location, offset: blah}, [])
  end
end
