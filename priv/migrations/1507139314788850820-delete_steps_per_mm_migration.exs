defmodule DeleteStepsPerMM do
  def run(json) do
    configuration = json["configuration"]

    new_config =
      configuration
      |> Map.delete("steps_per_mm_x")
      |> Map.delete("steps_per_mm_y")
      |> Map.delete("steps_per_mm_z")
      |> Map.delete("distance_mm_x")
      |> Map.delete("distance_mm_y")
      |> Map.delete("distance_mm_z")

    hardware = json["hardware"]
    new_params =
      hardware["params"]
      |> Map.put("movement_step_per_mm_x", hardware["params"]["movement_step_per_mm_x"] || configuration["steps_per_mm_x"] || 5)
      |> Map.put("movement_step_per_mm_y", hardware["params"]["movement_step_per_mm_y"] || configuration["steps_per_mm_y"] || 5)
      |> Map.put("movement_step_per_mm_z", hardware["params"]["movement_step_per_mm_z"] || configuration["steps_per_mm_z"] || 25)
    new_hardware = %{hardware | "params" => new_params}

    %{json | "configuration" => new_config, "hardware" => new_hardware}
  end
end
