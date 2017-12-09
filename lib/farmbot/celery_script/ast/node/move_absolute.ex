defmodule Farmbot.CeleryScript.AST.Node.MoveAbsolute do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  import Farmbot.CeleryScript.Utils
  use Farmbot.Logger

  allow_args [:location, :speed, :offset]

  def execute(%{location: location, speed: speed, offset: offset}, _, env) do
    env = mutate_env(env)
    with {:ok, pos_a} <- ast_to_vec3(location),
         {:ok, pos_b} <- ast_to_vec3(offset)
    do
      pos = vec3_math(pos_a, :+, pos_b)
      Logger.busy 2, "Moving to (#{pos.x}, #{pos.y}, #{pos.z})"
      speed_x = (speed / 100) * (Farmbot.BotState.get_param(:movement_max_spd_x) || 1)
      speed_y = (speed / 100) * (Farmbot.BotState.get_param(:movement_max_spd_y) || 1)
      speed_z = (speed / 100) * (Farmbot.BotState.get_param(:movement_max_spd_z) || 1)
      case Farmbot.Firmware.move_absolute(pos, speed_x |> round(), speed_y |> round(), speed_z |> round()) do
        :ok ->
          Logger.success 2, "Movement to (#{pos.x}, #{pos.y}, #{pos.z}) complete."
          {:ok, env}
        {:error, reason} -> {:error, reason, env}
      end
    else
      {:error, reason} -> {:error, reason, env}
    end
  end
end
