defmodule FarmbotExt.AMQP.ChannelSupervisor do
  @moduledoc false
  use Supervisor
  alias FarmbotExt.JWT

  alias FarmbotExt.AMQP.{
    NervesHubTransport,
    LogChannel,
    BotStateTransport,
    BotStateNGTransport,
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
      {NervesHubTransport, [jwt: jwt]},
      {LogChannel, [jwt: jwt]},
      {BotStateTransport, [jwt: jwt]},
      {BotStateNGTransport, [jwt: jwt]},
      {AutoSyncTransport, [jwt: jwt]},
      {CeleryScriptTransport, [jwt: jwt]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
