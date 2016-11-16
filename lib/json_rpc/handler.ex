alias Experimental.{GenStage}
defmodule RPC.MessageHandler do
  use GenStage
  import RPC.Parser
  @handler Application.get_env(:json_rpc, :handler)

  @doc """
  Requires configuration of a handler.
  Handler requires a callback of handle_incoming/1 to be defined
  which takes a parsed rpc message.
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
      |> @handler.handle_incoming
    end
    {:noreply, [], state}
  end
end
