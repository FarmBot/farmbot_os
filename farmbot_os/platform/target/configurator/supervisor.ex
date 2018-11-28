defmodule Farmbot.Target.Configurator.Supervisor do
  use Supervisor
  alias Farmbot.Target.Configurator.{Router, Validator}

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    transport_opts = [
      num_acceptors: 1
    ]

    opts = [port: 80, transport_options: transport_opts]

    children = [
      Validator,
      {Plug.Adapters.Cowboy, scheme: :http, plug: Router, options: opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
