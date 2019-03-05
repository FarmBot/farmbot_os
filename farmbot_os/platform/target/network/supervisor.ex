defmodule FarmbotOS.Platform.Target.Network.Supervisor do
  use Supervisor
  alias FarmbotCore.Config
  alias FarmbotOS.Platform.Target.{Network, Network.Distribution}

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:ok, hostname} = :inet.gethostname()
    confs = Config.get_all_network_configs()

    config =
      Map.new(confs, fn %{name: ifname} = settings ->
        {ifname, Network.validate_settings(settings)}
      end)

    distribution_children =
      Enum.map(confs, fn %{name: ifname} ->
        opts = %{
          ifname: ifname,
          mdns_domain: "#{hostname}.local",
          node_name: "farmbot",
          node_host: :mdns_domain
        }

        {Distribution, opts}
      end)

    children = [
      {Network, config: config} | distribution_children
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
