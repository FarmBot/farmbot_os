defmodule Farmbot.Logger.Console do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, [], [])
  end

  def init([]) do
    {:consumer, [], subscribe_to: [Farmbot.Logger]}
  end

  def handle_events(events, _, state) do
    for event <- events do
      IO.inspect event
    end
    {:noreply, [], state}
  end
end
