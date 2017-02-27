defmodule FPFE do
  def run(json) do
    configuration = json["configuration"]
    new_config = Map.put(configuration, "first_party_farmware", true)
    %{json | "configuration" => new_config}
  end
end
