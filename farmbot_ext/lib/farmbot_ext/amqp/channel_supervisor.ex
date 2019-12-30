defmodule FarmbotExt.AMQP.ChannelSupervisor do
  @moduledoc """
  Supervises AMQP channels
  """
  use Supervisor
  alias FarmbotExt.JWT

  alias FarmbotExt.AMQP.{
    LogChannel,
    PingPongChannel,
    BotStateChannel,
    AutoSyncChannel,
    CeleryScriptChannel,
    TelemetryChannel
  }

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([token]) do
    jwt = JWT.decode!(token)

    children = [
      {TelemetryChannel, [jwt: jwt]},
      {LogChannel, [jwt: jwt]},
      {PingPongChannel, [jwt: jwt]},
      {BotStateChannel, [jwt: jwt]},
      {AutoSyncChannel, [jwt: jwt]},
      {CeleryScriptChannel, [jwt: jwt]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
