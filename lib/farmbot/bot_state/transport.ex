defmodule Farmbot.Log do
  defstruct [
    :meta,
    :message,
    :created_at,
    :channels
  ]
end

defmodule Farmbot.BotState.Transport do
  @moduledoc """
  Serializes Farmbot's state to be send out to any subscribed transports.
  """

  @doc "Start a transport."
  @callback start_link(Farmbot.Bootstrap.Authorization.token, Farmbot.BotState.state_server) :: GenServer.on_start()

  @doc "Log a message."
  @callback log(Farmbot.Log.t) :: :ok

  @doc "Emit a message."
  @callback emit(Farmbot.CeleryScript.Ast.t) :: :ok

  @error_msg """
  Could not find :transport configuration.
  config.exs should have:

  config: :farmbot, :transport, [
    # any transport modules here.
  ]
  """

  @doc "All transports."
  def transports do
    Application.get_env(:farmbot, :transport) || raise @error_msg
  end

  @doc "Emit a message over all transports."
  def emit(%Farmbot.CeleryScript.Ast{} = msg) do
    for transport <- transports() do
      :ok = transport.emit(msg)
    end
  end

  @doc "Log a message over all transports."
  def log(%Farmbot.Log{} = log) do
    for transport <- transports() do
      :ok = transport.log(log)
    end
  end
end
