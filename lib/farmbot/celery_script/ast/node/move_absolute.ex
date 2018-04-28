defmodule Farmbot.CeleryScript.AST.Node.MoveAbsolute do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  import Farmbot.CeleryScript.Utils
  alias Farmbot.Firmware.Vec3
  import Farmbot.System.ConfigStorage, only: [get_config_value: 3]
  use Farmbot.Logger

  allow_args [:location, :speed, :offset]

  def execute(%{location: location, speed: speed, offset: offset}, _, env) do
    env = mutate_env(env)
    with {:ok, pos_a} <- ast_to_vec3(location),
         {:ok, pos_b} <- ast_to_vec3(offset)
    do
      pos = vec3_math(pos_a, :+, pos_b)
      maybe_log_busy(pos)
      speed_x = (speed / 100) * (Farmbot.BotState.get_param(:movement_max_spd_x) || 1)
      speed_y = (speed / 100) * (Farmbot.BotState.get_param(:movement_max_spd_y) || 1)
      speed_z = (speed / 100) * (Farmbot.BotState.get_param(:movement_max_spd_z) || 1)
      case Farmbot.Firmware.move_absolute(pos, speed_x |> round(), speed_y |> round(), speed_z |> round()) do
        :ok -> {:ok, env}
        {:error, reason} -> {:error, reason, env}
      end
    else
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp maybe_log_busy(%Vec3{} = pos) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Logger.busy 1, "Moving to #{inspect pos}"
    end
  end
end
