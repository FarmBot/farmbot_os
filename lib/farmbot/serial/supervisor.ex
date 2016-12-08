defmodule Farmbot.Serial.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  def init(env) do
    children = [
      worker(Farmbot.Serial.Handler, [env], restart: :permanent)
    ]
    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end

  def start_link(env) do
    # Log somethingdebug("Starting Serial")
    Supervisor.start_link(__MODULE__, env)
  end
end
