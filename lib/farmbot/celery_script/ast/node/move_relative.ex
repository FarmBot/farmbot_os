defmodule Farmbot.CeleryScript.AST.Node.MoveRelative do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  import Farmbot.CeleryScript.Utils
  allow_args [:x, :y, :z, :speed]

  def execute(%{x: x, y: y, z: z, speed: speed}, _, env) do
    env = mutate_env(env)
    %{x: cur_x, y: cur_y, z: cur_z} = Farmbot.BotState.get_current_pos()
    location = new_vec3(cur_x, cur_y, cur_z)
    offset = new_vec3(x, y, z)
    Farmbot.CeleryScript.AST.Node.MoveAbsolute.execute(%{location: location, offset: offset, speed: speed}, [], env)
  end
end
