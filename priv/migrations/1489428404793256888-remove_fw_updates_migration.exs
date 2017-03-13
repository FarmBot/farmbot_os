defmodule RemoveArduinoFwUpdates do
  def run(json) do
    configuration = json["configuration"]
    configuration = Map.delete(configuration, "fw_auto_update")
    %{json | "configuration" => configuration}
  end
end
