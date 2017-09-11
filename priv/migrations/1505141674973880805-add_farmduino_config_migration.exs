defmodule AddFarmduinoConfig do
  def run(json) do
    config = json["configuration"]
    new_config = Map.put(config, "farmware_hardware", "arduino")
    %{json | "configuration" => new_config }
  end
end
