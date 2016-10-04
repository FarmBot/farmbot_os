alias Experimental.{GenStage}
defmodule SequenceHandler do
  require IEx
  use GenStage
  require Logger

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    # Bootstarp the bot here.
    {:consumer, :ok, subscribe_to: [SequenceManager]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      do_handle(event)
    end
    {:noreply, [], state}
  end

  def do_handle({:exec_sequence, steps, id}) when is_list(steps) do
    Sequence.clean_steps
    Sequence.add_steps(steps, id)
    Sequence.execute(id)
  end

  # Unhandled event. Probably not implemented if it got this far.
  def do_handle(event) do
    Logger.debug("[SequenceHandler] (Probably not implemented) Unhandled Event: #{inspect event}")
  end
end
