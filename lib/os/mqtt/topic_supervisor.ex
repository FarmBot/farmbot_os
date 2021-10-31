defmodule FarmbotOS.MQTT.TopicSupervisor do
  use Supervisor

  alias FarmbotOS.MQTT.{
    BotStateHandler,
    LogHandler,
    PingHandler,
    RPCHandler,
    SyncHandler,
    TelemetryHandler,
    TerminalHandler
  }

  def start_link(args, opts \\ [name: __MODULE__]) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(opts) do
    child_opts = [
      client_id: Keyword.fetch!(opts, :client_id),
      username: Keyword.fetch!(opts, :username)
    ]

    mapper = fn child -> {child, child_opts} end

    list = [
      BotStateHandler,
      LogHandler,
      PingHandler,
      RPCHandler,
      SyncHandler,
      TelemetryHandler,
      TerminalHandler
    ]

    children = Enum.map(list, mapper)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
