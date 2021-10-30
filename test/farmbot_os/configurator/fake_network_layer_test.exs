defmodule FarmbotOS.Configurator.FakeNetworkLayerTest do
  alias FarmbotOS.Configurator.FakeNetworkLayer
  use ExUnit.Case

  test "fake data schema" do
    ifaces = FakeNetworkLayer.list_interfaces()
    scans = FakeNetworkLayer.scan("wlan0")
    assert Enum.count(scans) == 5
    assert Enum.count(ifaces) == 2
    assert {"eth0", %{mac_address: "not real lol"}} == Enum.at(ifaces, 0)
    assert Enum.at(scans, 0).bssid == "de:ad:be:ef"
  end
end
