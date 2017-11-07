defmodule Farmbot.Target.Network do
  @moduledoc "Bring up network."

  @behaviour Farmbot.System.Init
  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.NetworkInterface
  alias Farmbot.Target.Network.Manager, as: NetworkManager
  use Supervisor
  use Farmbot.Logger

  def test_dns(hostname \\ 'nerves-project.org') do
    :inet_res.gethostbyname(hostname)
  end

  # TODO Expand this.
  def to_network_config(config)

  def to_network_config(%NetworkInterface{ssid: ssid, psk: psk, type: "wireless"} = config) do
    Logger.debug(3, "wireless network config: ssid: #{config.ssid}, psk: #{config.psk}")
    {config.name, [ssid: ssid, key_mgmt: :"WPA-PSK", psk: psk]}
  end

  def to_network_config(%NetworkInterface{type: "wired"} = config) do
    {config.name, []}
  end

  def to_child_spec({interface, opts}) do
    worker(NetworkManager, [interface, opts])
  end

  def start_link(_, opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    config = ConfigStorage.all(NetworkInterface)
    Logger.info(3, "Starting Networking")
    children = config |> Enum.map(&to_network_config/1) |> Enum.map(&to_child_spec/1)
    supervise(children, strategy: :one_for_one)
  end
end
