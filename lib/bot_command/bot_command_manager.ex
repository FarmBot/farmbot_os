defmodule BotCommandManager do
  use GenEvent
  require Logger

  def start_link() do
    GenEvent.start_link([])
  end

  # add event to the log
  def handle_event({event, params}, events) do
    {:ok, [{event, params} | events]}
  end

  def handle_event(:e_stop, _events) do
    # Destroy the event queue
    {:ok, []}
  end

  # dump teh current events to be handled
  def handle_call(:events, events) do
    {:ok, Enum.reverse(events), []}
  end

end
