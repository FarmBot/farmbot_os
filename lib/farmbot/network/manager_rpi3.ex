defmodule Module.concat([Farmbot, Network, Handler, "rpi3"]) do
  @moduledoc """
    Event manager for network on Raspberry Pi 3
  """
  defmodule State, do: defstruct [:parent]
  @behaviour Farmbot.Network.Handler
  require Logger

  def manager, do: {:ok, Nerves.NetworkInterface.event_manager}
  def init({parent, _config}) do
    Process.flag :trap_exit, true
    Logger.debug ">> rpi3 networking handler starting."
    {:ok, %State{parent: parent}}
  end

  # event when we have an ip address.
  def handle_event({:udhcpc, _, :bound, %{ipv4_address: address}}, state) do
    # NetMan.on_ip(address)
    {:ok, state}
  end
  def handle_event(_, state), do: {:ok, state}

  def handle_call()

  def terminate(_, state) do
    # TODO MAKE SURE HOSTAPD IS NOT RUNNING
  end
end
