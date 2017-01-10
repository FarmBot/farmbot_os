defmodule Module.concat([Farmbot, System, "rpi2", Network, EventManager]) do
  use GenEvent
  require Logger

  def handle_event({:udhcpc, _, :bound,
    %{ipv4_address: _address, ifname: _interface}}, state)
  do
    Farmbot.System.Network.on_connect(fn() ->
      nil
    end)
    {:ok, state}
  end

    # just print hostapd data
  def handle_event({:hostapd, data}, state) do
    Logger.debug ">> got some hostapd data: #{data}"
    {:ok, state}
  end

    # def handle_event(event, state) do
    #   Logger.warn "got event: #{inspect event}"
    #   {:ok, state}
    # end

    # handle stray events that we don't care about
  def handle_event(_, state), do: {:ok, state}
end
