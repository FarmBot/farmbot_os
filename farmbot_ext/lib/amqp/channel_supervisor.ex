defmodule Farmbot.AMQP.ChannelSupervisor do
  @moduledoc false
  use Supervisor
  alias Farmbot.JWT

  alias Farmbot.AMQP.{
    LogTransport,
    BotStateTransport,
    AutoSyncTransport,
    CeleryScriptTransport
  }

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([token]) do
    Process.flag(:sensitive, true)
    jwt = JWT.decode!(token)

    children = [
      {LogTransport, [jwt: jwt]},
      {BotStateTransport, [jwt: jwt]},
      {AutoSyncTransport, [jwt: jwt]},
      {CeleryScriptTransport, [jwt: jwt]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
