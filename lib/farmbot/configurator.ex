defmodule Farmbot.Configurator do
  @moduledoc """
    A plug web application with a mini REST interface, and websocket handler.
  """

  use Supervisor
  alias Farmbot.Configurator.Router
  alias Farmbot.Configurator.SocketHandler
  alias Plug.Adapters.Cowboy.Handler, as: CowboyHandler
  require Logger

  @port Application.get_env(:farmbot, :configurator_port, 4000)

  def init([]) do
    Logger.info ">> Configurator init!"
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Router, [],
        [port: @port, dispatch: [dispatch()], acceptors: 10 ]),
     ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  defp dispatch do
    {:_, [
      {"/ws", SocketHandler, []},
      {"/debug_log", Farmbot.DebugLog.SocketHandler, []},
      {:_, CowboyHandler, {Router, []}},
      ]}
  end
end
