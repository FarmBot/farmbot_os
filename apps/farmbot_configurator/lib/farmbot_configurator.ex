defmodule Farmbot.Configurator do
  use Supervisor
  alias Farmbot.Configurator.Router
  require Logger
  @port Application.get_env(:farmbot_configurator, :port, 4000)
  @env Mix.env

  def init([]) do
    Logger.debug ">> Configurator init."
    children = [
      Plug.Adapters.Cowboy.child_spec(
        :http, Router, [], port: @port, dispatch: dispatch)
     ] ++ maybe_webpack
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

  def start(_type, _), do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  defp dispatch do
  [
    {:_, [
      {"/ws", Farmbot.Configurator.SocketHandler, []},
      {:_, Plug.Adapters.Cowboy.Handler, {Router, []}}
    ]}
  ]
  end
end
