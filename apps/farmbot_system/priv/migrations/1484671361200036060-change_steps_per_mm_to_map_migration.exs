defmodule StepsPerMM do
  require Logger

  def run(json) do
    s = json["configuration"]["steps_per_mm"]
    if is_integer(s) do
      config = %{json["configuration"] | "steps_per_mm" => %{"x" => s, "y" => s, "z" => s}}
      %{json | "configuration" => config}
    end
  end
end
