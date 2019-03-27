defmodule FarmbotExt.AMQP.ChannelSupervisor do
  @moduledoc false
  use Supervisor
  alias FarmbotExt.JWT

  alias FarmbotExt.AMQP.{
    NervesHubChannel,
    LogChannel,
    BotStateChannel,
    BotStateNGChannel,
    AutoSyncChannel,
    CeleryScriptChannel
  }

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([token]) do
    Process.flag(:sensitive, true)
    jwt = JWT.decode!(token)

    children = [
      {NervesHubChannel, [jwt: jwt]},
      {LogChannel, [jwt: jwt]},
      {BotStateChannel, [jwt: jwt]},
      {BotStateNGChannel, [jwt: jwt]},
      {AutoSyncChannel, [jwt: jwt]},
      {CeleryScriptChannel, [jwt: jwt]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
