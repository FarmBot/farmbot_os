defmodule MaxMovementRetries do
  def run(json) do
    config = json["configuration"]
    if config["max_movement_retries"] do
      json
    else
      %{json | "configuration" => Map.put(config, "max_movement_retries", 5) }
    end
  end
end
