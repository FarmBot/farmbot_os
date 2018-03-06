defmodule Farmbot.Target.Network do
  @moduledoc "Bring up network."

  @behaviour Farmbot.System.Init
  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [get_config_value: 3]
  alias ConfigStorage.NetworkInterface
  alias Farmbot.Target.Network.Manager, as: NetworkManager
  use Supervisor
  use Farmbot.Logger

  def test_dns(hostname \\ nil)

  def test_dns(nil) do
    case get_config_value(:string, "authorization", "server") do
      nil -> 'nerves-project.org'
      <<"https://" <> host :: binary>> -> test_dns(to_charlist(host))
      <<"http://"  <> host :: binary>> -> test_dns(to_charlist(host))
    end
  end

  def test_dns(hostname) do
    :inet_res.gethostbyname(hostname)
  end

  # TODO Expand this to allow for more settings.
  def to_network_config(config)

  def to_network_config(%NetworkInterface{ssid: ssid, psk: psk, type: "wireless"} = config) do
    Logger.debug(3, "wireless network config: ssid: #{config.ssid}")
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
    children = config
      |> Enum.map(&to_network_config/1)
      |> Enum.map(&to_child_spec/1)
      |> Enum.uniq() # Don't know why/if we need this?
    supervise(children, strategy: :one_for_one)
  end
end
