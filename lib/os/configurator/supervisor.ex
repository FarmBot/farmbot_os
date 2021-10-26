defmodule FarmbotOS.Configurator.Supervisor do
  @moduledoc """
  Supervisor for the Configurator Web stack
  """

  use Supervisor
  alias FarmbotOS.Configurator.{Router, LoggerSocket}

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    :ets.new(:configurator_session, [
      :named_table,
      :public,
      read_concurrency: true
    ])

    transport_opts = [
      num_acceptors: 1
    ]

    opts = [
      port: default_port(),
      transport_options: transport_opts,
      dispatch: dispatch()
    ]

    children = [
      {Plug.Adapters.Cowboy, scheme: :http, plug: Router, options: opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp default_port do
    case System.get_env("CONFIGURATOR_PORT") do
      nil -> 80
      str -> String.to_integer(str)
    end
  end

  defp dispatch() do
    [
      {:_,
       [
         {"/logger_socket", LoggerSocket, []},
         {:_, Plug.Cowboy.Handler, {Router, []}}
       ]}
    ]
  end
end
