defmodule MaxMovementRetriesRevert do
  def run(json) do
    config = json["configuration"]
    new_config = Map.delete(config, "max_movement_retries")
    %{json | "configuration" => new_config }
  end
end
