defmodule Module.concat([Farmbot, Network, Handler, "rpi0"]) do
  @moduledoc """
    Event manager for network on Raspberry Pi 0 and 1
  """

  @behaviour Farmbot.Network.Handler
  require Logger
  alias Nerves.NetworkInterface
  use GenEvent

  @doc false
  def manager, do: {:ok, NetworkInterface.event_manager}

  @doc false
  def init(_) do
    Logger.debug ">> rpi0 networking handler starting."
    {:ok, []}
  end

  # scan for wifi. This should work in host and client mode.
  def handle_call({:scan, iface}, state) do
    {hc, 0} = System.cmd("iw", [iface, "scan", "ap-force"])
    {:ok, hc |> clean_ssid, state}
  end

  def handle_call(:ok, state) do
    {:ok, :ok, state}
  end

  # don't crash on random calls
  def handle_call(_, state) do
    {:ok, :unhandled, state}
  end

  # this probably could be less not good
  defp clean_ssid(hc) do
    hc
    |> String.replace("\t", "")
    |> String.replace("\\x00", "")
    |> String.split("\n")
    |> Enum.filter(fn(s) -> String.contains?(s, "SSID") end)
    |> Enum.map(fn(z) -> String.replace(z, "SSID: ", "") end)
    |> Enum.filter(fn(z) -> String.length(z) != 0 end)
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
  def terminate(_, _state), do: :ok
end
