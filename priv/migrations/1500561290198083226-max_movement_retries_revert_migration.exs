defmodule MaxMovementRetriesRevert do
  def run(json) do
    config = json["configuration"]
    Map.delete(config, "max_movement_retries")
    %{json | "configuration" => new_config }
  end
end
