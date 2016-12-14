defmodule Network.EventManager do
  use GenEvent
  require Logger

  def handle_event({:udhcpc, _, :bound, %{ipv4_address: address}}, state) do
    # NetMan.on_ip(address)
    {:ok, state}
  end

  def handle_event({:nerves_wpa_supplicant, _, wpa_event}, state) when is_atom(wpa_event) do
    #:"CTRL-EVENT-SSID-TEMP-DISABLED id=0 ssid=\"supersecretssid\" auth_failures=2 duration=20 reason=WRONG_KEY"
    event_string = Atom.to_string(wpa_event)
    if(String.contains?(event_string, "reason=WRONG_KEY")) do
      # NetMan.bad_key
    end
    {:ok, state}
  end

  def handle_event(_event, state) do
    #IO.inspect event
    #IO.inspect state
    {:ok, state}
  end
end
