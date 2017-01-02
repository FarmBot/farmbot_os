defmodule Module.concat([Farmbot, Network, Handler, "rpi3"]) do
  @moduledoc """
    Event manager for network on Raspberry Pi 3
  """

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{parent: pid | nil}
    defstruct [:parent]
  end

  @behaviour Farmbot.Network.Handler
  require Logger
  alias Nerves.NetworkInterface

  @doc false
  def manager, do: {:ok, NetworkInterface.event_manager}
  @doc false
  def init({parent, _config}) do
    Process.flag :trap_exit, true
    Logger.debug ">> rpi3 networking handler starting."
    {:ok, %State{parent: parent}}
  end

  # {:udhcpc, pid, :bound,
  #  %{domain: "T-mobile.com",
  #    ifname: "eth0",
  #    ipv4_address: "192.168.29.186",
  #    ipv4_broadcast: "192.168.29.255",
  #    ipv4_gateway: "192.168.29.1",
  #    ipv4_subnet_mask: "255.255.255.0",
  #    nameservers: ["192.168.29.1"]}}


  # event when we have an ip address.
  def handle_event({:udhcpc, _, :bound,
    %{ipv4_address: address, ifname: interface}}, state)
  do
    GenServer.cast(state.parent, {:connected, interface, address})
    {:ok, state}
  end

  def handle_event({:hostapd, data}, state) do
    Logger.debug ">> got some hostapd data: #{data}"
    {:ok, state}
  end
  # def handle_event(event, state) do
  #   Logger.warn "got event: #{inspect event}"
  #   {:ok, state}
  # end

  def handle_event(_, state), do: {:ok, state}
  def terminate(_, _state), do: :ok
end
