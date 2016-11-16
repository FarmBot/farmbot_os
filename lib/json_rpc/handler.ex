alias Experimental.{GenStage}
defmodule RPC.MessageHandler do
  use GenStage
  require Logger
  import JsonRpc.Parser
  import Farmbot.RPC.Handler
  @transport Application.get_env(:json_rpc, :transport)

  @doc """
    This is where all JSON RPC messages come in.
    Currently only from Mqtt, but is technically transport agnostic.
    Right now we set @transport to Mqtt.Handler, but it could technically be
    In config and set to anything that can emit and recieve JSON RPC messages.
  """

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(_args) do
    {:consumer, :ok, subscribe_to: [RPC.MessageManager]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      parse(event)
      |> handle_incoming
    end
    {:noreply, [], state}
  end

  # when a request message comes in, we send an ack that we got the message
  def handle_incoming(%Request{} = rpc) do
    case handle_request(rpc.method, rpc.params) do
      :ok ->
        @transport.emit(ack_msg(rpc.id))
      {:error, name, message} ->
        @transport.emit(ack_msg(rpc.id, {name, message}))
    end
  end

  def handle_incoming(%Response{} = rpc) do
    Logger.warn("Farmbot doesn't know what to do with this message:
                  #{inspect rpc}")
  end

  def handle_incoming(%Notification{} = rpc) do
    Logger.warn("Farmbot doesn't know what to do with this message:
                  #{inspect rpc}")
  end

  def handle_incoming(_) do
    Logger.warn("Farmbot got a malformed RPC Message.")
  end

  @doc """
    Shortcut for logging a message to the frontend.
    =  Channel can be  =
    |  :ticker   |
    |  :error_ticker   |
    |  :error_toast    |
    |  :success_toast  |
    |  :warning_toast  |
  """
  def log(message, channel \\ [], tags \\ [])
  def log(message, channels, tags)
  when is_bitstring(message)
   and is_list(channels)
   and is_list(tags) do
     v = log_msg(message, channels, tags)
    @transport.emit(v)
  end

  # This is what actually updates the rest of the world about farmbots status.
  def send_status do
    m = %{id: nil,
          method: "status_update",
          params: [Farmbot.BotState.get_status] }
      @transport.emit(Poison.encode!(m))
  end
end
