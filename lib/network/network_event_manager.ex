defmodule Network.EventManager do
  use GenEvent
  require Logger

  def handle_event({:udhcpc, _, :bound, %{ipv4_address: address}}, state) do
    on_ip(address)
    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end

  def on_ip(address) do
    Logger.debug("WE ARE CONNECTED")
    Wifi.set_connected(true)
    Node.stop
    full_node_name = "farmbot@#{address}" |> String.to_atom
    {:ok, _pid} = Node.start(full_node_name)
  end
end
