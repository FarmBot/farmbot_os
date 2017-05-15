defmodule RemoveDualWlan do
  def run(json) do
    network = json["network"]
    if network do
      interfaces = network["interfaces"]
      new_interfaces =
        if interfaces["wlan1"] do
          Map.delete(interfaces, "wlan1")
        else
          interfaces
        end
      new_network = %{network | "interfaces" => new_interfaces}
      %{json | "network" => new_network}
    else
      json
    end
  end
end
