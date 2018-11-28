defmodule Farmbot.Target.Network.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:ok, hostname} = :inet.gethostname()
    confs = Farmbot.Config.Repo.all(Farmbot.Config.NetworkInterface)

    config =
      Map.new(confs, fn %{name: ifname} = settings ->
        {ifname, Farmbot.Target.Network.validate_settings(settings)}
      end)

    distribution_children =
      Enum.map(confs, fn %{name: ifname} ->
        opts = %{
          ifname: ifname,
          mdns_domain: "#{hostname}.local",
          node_name: "farmbot",
          node_host: :mdns_domain
        }

        {Farmbot.Target.Network.Distribution, opts}
      end)

    children = [
      {Farmbot.Target.Network, config: config} | distribution_children
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
