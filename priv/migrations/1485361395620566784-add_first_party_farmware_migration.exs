defmodule FPF do
  def run(json) do
    configuration = json["configuration"]
    if configuration["first_party_farmware"] do
      # if the already exist its fine
      json
    else
      new_config = Map.put(configuration, "first_party_farmware", false)
      %{json | "configuration" => new_config}
    end
  end
end
