alias Experimental.GenStage
alias Farmbot.BotState.Monitor
alias Farmbot.BotState.Monitor.State, as: MonState
defmodule Farmbot.Transport do
  @moduledoc """
    Serializes Farmbot's state to be send out to any subscribed transports.
  """
  use GenStage
  require Logger

  defmodule Serialized do
    @moduledoc false
    defstruct []
  end

  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Logger.debug ">> transport init"
    {:producer_consumer, %Serialized{}, subscribe_to: [Monitor]}
  end

  def handle_events([%MonState{} = monstate], _from, _) do
    Logger.debug ">> Got state update"
    {:noreply, [monstate], monstate}
  end

  def handle_events(t, _, state) do
    Logger.warn "FIX THIS: #{inspect t}"
    {:noreply, [nil], state}
  end
end
