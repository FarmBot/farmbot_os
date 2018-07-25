defmodule Farmbot.AMQP.ChannelSupervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([token]) do
    Process.flag(:sensitive, true)
    conn = Farmbot.AMQP.ConnectionWorker.connection()
    jwt = Farmbot.Jwt.decode!(token)
    children = [
      {Farmbot.AMQP.LogTransport,          [conn, jwt]},
      {Farmbot.AMQP.BotStateTransport,     [conn, jwt]},
      {Farmbot.AMQP.AutoSyncTransport,     [conn, jwt]},
      {Farmbot.AMQP.CeleryScriptTransport, [conn, jwt]}
    ]
    Supervisor.init(children, [strategy: :one_for_one])
  end
end
