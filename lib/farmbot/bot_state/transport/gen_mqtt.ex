defmodule Farmbot.BotState.Transport.GenMQTT do
  use GenStage
  require Logger

  def start_link(opts) do
    GenStage.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    {:ok, pid} = Farmbot.Transport.GenMQTTClient.start_link()
    {:consumer, {pid, nil}, subscribe_to: [Farmbot.BotState]}
  end

  def handle_events(events, _, {pid, state}) do
    new_state = blah(events, state)
    if new_state != state do
      send pid, {:bot_state, new_state}
      Logger.info "State: #{inspect new_state}"
    else
      # Logger.info "no change"
    end
    {:noreply, [], {pid, new_state}}
  end

  def blah([], state), do: state
  def blah([event | rest], _state) do
    blah(rest, event)
  end
end
