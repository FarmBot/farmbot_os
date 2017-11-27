defmodule Farmbot.CeleryScript.AST.Node.MoveAbsolute do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  import Farmbot.CeleryScript.Utils

  allow_args [:location, :speed, :offset]

  def execute(%{location: location, speed: speed, offset: offset}, _, env) do
    env = mutate_env(env)
    with {:ok, pos_a} <- ast_to_vec3(location),
         {:ok, pos_b} <- ast_to_vec3(offset)
    do
      pos = vec3_math(pos_a, :+, pos_b)
      speed_x = speed * (Farmbot.BotState.get_param(:movement_max_spd_x) || 1)
      speed_y = speed * (Farmbot.BotState.get_param(:movement_max_spd_y) || 1)
      speed_z = speed * (Farmbot.BotState.get_param(:movement_max_spd_z) || 1)
      case Farmbot.Firmware.move_absolute(pos, speed_x, speed_y, speed_z) do
        :ok -> {:ok, env}
        {:error, reason} -> {:error, reason, env}
      end
    else
      {:error, reason} -> {:error, reason, env}
    end
  end
end
