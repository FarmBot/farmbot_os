alias Experimental.{GenStage}
defmodule RPC.MessageHandler do
  use GenStage
  import RPC.Parser

  @doc """
    Requires configuration of a handler.
    Handler requires a callback of handle_incoming/1 to be defined
    which takes a parsed rpc message. Should probably make @handler a behavior
    and document it. l o l.
  """

  def start_link(handler) do
    GenStage.start_link(__MODULE__, handler)
  end

  def init(handler) do
    {:consumer, handler, subscribe_to: [RPC.MessageManager]}
  end

  def handle_events(events, _from, handler) do
    for event <- events, do: parse(event) |> handler.handle_incoming
    {:noreply, [], handler}
  end
end
