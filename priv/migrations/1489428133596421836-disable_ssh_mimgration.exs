defmodule DisableSSH do
  def run(json) do
    network = json["network"]
    net_config =
      if network do
        # if we have a network config, make ssh key false
        Map.put(network, "ssh", false)
      else
        # if no network, just make it false.
        false
      end

    %{json | "network" => net_config}
  end
end
