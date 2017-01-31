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
     ] ++ maybe_webpack()
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  defp maybe_webpack do
    if System.get_env("USE_WEBPACK") do
      IO.puts "starting webpack"
      [worker(Farmbot.Configurator.WebPack, [])]
    else
      []
    end
  end

  def start(_type, _),
    do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  # This is a copy paste magic that makes the websocket work.
  # Im not entirely sure how it works, but it does.
  defp dispatch do
    {:_, [ {"/ws", SocketHandler, []}, {:_, CowboyHandler, {Router, []}}]}
  end
end
