defmodule Farmbot.System.Debug do
  use Supervisor
  alias Plug.Adapters.Cowboy

  def start_link(_, opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    options = [
      port: 5000,
      dispatch: [
        {:_, [
          {"/wobserver/ws", Wobserver.Web.Client, []},
          {:_, Cowboy.Handler, {Farmbot.System.DebugRouter, []}}
        ]}
      ],
    ]
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Farmbot.System.DebugRouter, [], options)
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
