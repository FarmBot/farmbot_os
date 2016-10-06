defmodule BotCommandManager do
  use GenEvent
  require Logger

  def start_link() do
    GenEvent.start_link( [{:not_doing_stuff, []}] )
  end

  # add event to the log
  def handle_event({event, params}, [{asdf, events}]) do
    {:ok, [{asdf, [{event, params} | events]}]}
  end

  def handle_event(:e_stop, _) do
    # Destroy the event queue
    {:ok, [{:not_doing_stuff, []}] }
  end

  # dump teh current events to be handled
  def handle_call(:events, [{:not_doing_stuff, events}]) do
    {:ok, Enum.reverse(events), [{:doing_stuff, []}] }
  end

  def handle_call(:events, [{:doing_stuff, events}]) do
    {:ok, [], [{:doing_stuff, events}] }
  end

  def handle_call(:done_doing_stuff, [{_, events}]) do
    {:ok, :ok, [{:not_doing_stuff, events}] }
  end

  def handle_call(:doing_stuff?, [{doing_stuff, events}]) do
    {:ok, doing_stuff, [{doing_stuff, events}]}
  end

end
