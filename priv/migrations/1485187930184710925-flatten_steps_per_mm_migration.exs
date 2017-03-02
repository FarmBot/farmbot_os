defmodule StepsPerMM do
  def run(json) do
    configuration = json["configuration"]

    case configuration["steps_per_mm"] do
      # if this is the shape of steps_per_mm update it.
      %{"x" => x, "y" => y, "z" => z} ->
        config =
          configuration
          |> Map.delete("steps_per_mm")
          |> Map.merge(%{"steps_per_mm_x" => x, "steps_per_mm_y" => y, "steps_per_mm_z" => z})
        %{json | "configuration" => config}
      # if that pattern doesnt match, we don't need to fix anything. Move along.
      _ -> json
    end
  end
end
