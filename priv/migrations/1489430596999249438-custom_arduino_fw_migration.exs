defmodule CustomArduinoFwUpdates do
  def run(json) do
    hardware = json["hardware"]
    hardware = Map.put(hardware, "custom_firmware", false)
    %{json | "hardware" => hardware}
  end
end
