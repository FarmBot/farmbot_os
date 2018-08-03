defmodule Farmbot.OS.IOLayer.MoveAbsolute do
  alias Farmbot.Firmware.Vec3
  import Farmbot.Config, only: [get_config_value: 3]
  require Farmbot.Logger

  def execute(%{location: %{x: _, y: _, z: _} = pos_a,
                offset: %{x: _, y: _, z: _} = pos_b,
                speed: speed}, []) do
    pos = vec3_math(pos_a, :+, pos_b)
    maybe_log_busy(pos)
    speed_x = (speed / 100) * (get_config_value(:float, "hardware_params", "movement_max_spd_x") || 1)
    speed_y = (speed / 100) * (get_config_value(:float, "hardware_params", "movement_max_spd_y") || 1)
    speed_z = (speed / 100) * (get_config_value(:float, "hardware_params", "movement_max_spd_z") || 1)
    case Farmbot.Firmware.move_absolute(pos, speed_x |> round(), speed_y |> round(), speed_z |> round()) do
      :ok -> :ok
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  defp maybe_log_busy(%Vec3{} = pos) do
    unless get_config_value(:bool, "settings", "firmware_input_log") do
      Farmbot.Logger.busy 1, "Moving to #{inspect pos}"
    end
  end

  def vec3_math(%{x: xa, y: ya, z: za}, fun, %{x: xb, y: yb, z: zb}) do
    res_x = apply(Kernel, fun, [xa || 0, xb || 0])
    res_y = apply(Kernel, fun, [ya || 0, yb || 0])
    res_z = apply(Kernel, fun, [za || 0, zb || 0])
    %Vec3{x: res_x, y: res_y, z: res_z}
  end
end
