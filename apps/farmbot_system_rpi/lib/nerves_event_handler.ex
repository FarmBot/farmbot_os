defmodule Module.concat([Farmbot, System, "rpi", Network, EventManager]) do
  use GenEvent
  require Logger

  def handle_event({:udhcpc, _, :bound,
    %{ipv4_address: _address, ifname: _interface}}, state)
  do
    spawn fn() ->
      Farmbot.System.Network.on_connect(fn() ->
        Logger.debug ">> is waiting for linux and network and what not."
        Process.sleep(5000) # ye old race linux condidtion
      end)
    end
    {:ok, state}
  end

    # just print hostapd data
  def handle_event({:hostapd, data}, state) do
    Logger.debug ">> got some hostapd data: #{data}"
    {:ok, state}
  end

    # handle stray events that we don't care about
  def handle_event(_, state), do: {:ok, state}
end
