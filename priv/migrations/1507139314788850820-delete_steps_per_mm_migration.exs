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


    %{json | "configuration" => new_config}
  end
end
