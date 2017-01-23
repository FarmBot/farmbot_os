defmodule DistanceMM do
  def run(json) do
    configuration = json["configuration"]
    dis_x = configuration["distance_mm_x"]
    dis_y = configuration["distance_mm_y"]
    dis_z = configuration["distance_mm_z"]
    if dis_x && dis_y && dis_z do
      # if the already exist its fine
      json
    else
      # if those didnt exist, create them
      new_config =
        configuration
        |> Map.merge(
          %{"distance_mm_x" => 1500,
            "distance_mm_y" => 3000,
            "distance_mm_z" => 800})
      %{json | "configuration" => new_config}
    end
  end
end
