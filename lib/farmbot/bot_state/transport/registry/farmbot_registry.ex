defmodule Farmbot.BotState.Transport.Registry do
  @moduledoc """
  Publishes Farmbot's state to local registry.
  """

  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:consumer, %{cache: nil}, [subscribe_to: [Farmbot.BotState]]}
  end

  def handle_events(events, _from, state) do
    new_cache = Enum.reduce(events, state.cache, fn(bot_state, _cache) ->
      bot_state
    end)
    if new_cache != state.cache do
      Farmbot.System.Registry.dispatch(:bot_state, new_cache)
      {:noreply, [], %{state | cache: new_cache}}
    else
      {:noreply, [], state}
    end
  end
end
