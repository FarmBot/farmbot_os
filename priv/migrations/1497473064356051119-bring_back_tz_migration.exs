defmodule ReEnableTZ do
  def run(json) do
    config = json["configuration"]
    if config["timezone"] do
      json
    else
      %{json | "configuration" => Map.put(config, "timezone", nil) }
    end
  end
end
