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

  @port Application.get_env(:farmbot, :configurator_port, 4000)
  @streamer_port Application.get_env(:farmbot, :streamer_port, 4040)

  def init([]) do
    Logger.debug ">> Configurator init!"
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Router, [], port: @port,
        dispatch: [dispatch()]),
      Plug.Adapters.Cowboy.child_spec(:http, Streamer, [], port: @streamer_port)
     ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  defp dispatch do
    {:_, [{"/ws", SocketHandler, []}, {:_, CowboyHandler, {Router, []}}]}
  end
end
