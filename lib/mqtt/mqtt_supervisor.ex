defmodule Mqtt.Supervisor do
  require Logger
  use Supervisor

  def init(_args) do
    children = [worker(Mqtt.Handler, [[]], restart: :permanent)]
    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end

  def start_link(args) do
    Logger.debug("MQTT INIT")
    Supervisor.start_link(__MODULE__, args)
  end
end
