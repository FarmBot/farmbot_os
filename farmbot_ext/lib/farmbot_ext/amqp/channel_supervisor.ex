defmodule FarmbotExt.AMQP.ChannelSupervisor do
  @moduledoc """
  Supervises AMQP channels
  """
  use Supervisor
  alias FarmbotExt.JWT

  alias FarmbotExt.AMQP.{
    AutoSyncChannel,
    BotStateChannel,
    CeleryScriptChannel,
    LogChannel,
    PingPongChannel,
    TelemetryChannel,
    TerminalChannel,
  }

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([token]) do
    Supervisor.init(children(JWT.decode!(token)), strategy: :one_for_one)
  end

  def children(jwt) do
    config = Application.get_env(:farmbot_ext, __MODULE__) || []
    Keyword.get(config, :children, [
      {TelemetryChannel, [jwt: jwt]},
      {LogChannel, [jwt: jwt]},
      {PingPongChannel, [jwt: jwt]},
      {BotStateChannel, [jwt: jwt]},
      {AutoSyncChannel, [jwt: jwt]},
      {CeleryScriptChannel, [jwt: jwt]},
      {TerminalChannel, [jwt: jwt]}
    ])
  end
end
