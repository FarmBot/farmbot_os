defmodule Farmbot.System.NervesCommon.EventManager do
  use GenEvent
  require Logger

  def handle_event({:udhcpc, _, :bound,
    %{ipv4_address: _address, ifname: _interface}}, state)
  do
    spawn fn() ->
      Farmbot.System.Network.on_connect(fn() ->
        Logger.info ">> is waiting for linux and network and what not."
        Process.sleep(5000) # ye old race linux condidtion
      end)
    end
    {:ok, state}
  end

  def handle_event({:nerves_wpa_supplicant, _pid, event}, state) when is_atom(event) do
    event = event |> Atom.to_string
    wrong_key? = event |> String.contains?("reason=WRONG_KEY")
    not_found? = event |> String.contains?("CTRL-EVENT-NETWORK-NOT-FOUND")
    if wrong_key?, do: Farmbot.System.factory_reset
    if not_found?, do: Farmbot.System.factory_reset
    {:ok, state}
  end

    # just print hostapd data
  def handle_event({:hostapd, data}, state) do
    Logger.info ">> got some hostapd data: #{data}"
    {:ok, state}
  end

    # handle stray events that we don't care about
  def handle_event(_, state), do: {:ok, state}
end
