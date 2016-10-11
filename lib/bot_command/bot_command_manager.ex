defmodule BotCommandManager do
  use GenEvent
  require Logger

  def handle_event(:e_stop, _) do
    # Destroy the event queue
    {:ok, []}
  end

  # add event to the log
  def handle_event({event, params}, events) do
    {:ok, [{event, params} | events]}
  end

  # dump teh current events to be handled
  def handle_call(:events, events) do
    {:ok, Enum.reverse(events), [] }
  end
end
