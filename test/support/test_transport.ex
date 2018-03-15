defmodule Farmbot.BotState.Transport.Test do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def stop(reason) do
    GenStage.stop(__MODULE__, reason)
  end

  def init([]) do
    {:consumer, :no_state, subscribe_to: [Farmbot.BotState, Farmbot.Logger]}
  end

  def handle_events(_, _, state) do
    {:noreply, [], state}
  end
end
