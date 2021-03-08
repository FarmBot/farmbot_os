defmodule FarmbotExt.MQTT.TopicSupervisor do
  use Supervisor

  def start_link(args, opts \\ [name: __MODULE__]) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(opts) do
    child_opts = [
      client_id: Keyword.fetch!(opts, :client_id),
      username: Keyword.fetch!(opts, :username)
    ]

    children = [
      {FarmbotExt.MQTT.PingHandler, child_opts},
      {FarmbotExt.MQTT.TerminalHandler, child_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
