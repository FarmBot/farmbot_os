defmodule FarmbotOS.Configurator.FakeNetworkLayer do
  @behaviour FarmbotOS.Configurator.NetworkLayer

  @impl FarmbotOS.Configurator.NetworkLayer
  def list_interfaces() do
    [{"eth0", %{mac_address: "not real lol"}}]
  end

  @impl FarmbotOS.Configurator.NetworkLayer
  def scan(_ifname) do
    []
  end
end
