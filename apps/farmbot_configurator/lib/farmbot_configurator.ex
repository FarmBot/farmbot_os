defmodule Farmbot.Configurator do
  @moduledoc """
    A plug web application with a mini REST interface, and websocket handler.
  """

  use Supervisor
  alias Farmbot.Configurator.Router
  alias Farmbot.Configurator.Streamer
  alias Farmbot.Configurator.SocketHandler
  alias Plug.Adapters.Cowboy.Handler, as: CowboyHandler
  require Logger
  @port Application.get_env(:farmbot_configurator, :port, 4000)

  def init([]) do
    Logger.debug ">> Configurator init!"
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Router, [], port: @port, dispatch: [dispatch()]),
      Plug.Adapters.Cowboy.child_spec(:http, Streamer, [], port: 4040)
     ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def start(_type, _),
    do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  defp dispatch do
    {:_, [{"/ws", SocketHandler, []}, {:_, CowboyHandler, {Router, []}}]}
  end
end
