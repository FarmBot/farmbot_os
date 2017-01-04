defmodule StateDebugger do
  alias Farmbot.BotState
  alias BotState.EventManager
  alias BotState.Monitor
  @moduledoc false
  use GenEvent
  def handle_event({:dispatch, state_},_) do
    {:ok, state_}
  end

  def handle_call(:state, state_) do
    {:ok, state_, state_}
  end

  def state do
    GenEvent.call(EventManager, __MODULE__, :state)
  end

  def start do
    Monitor.add_handler(__MODULE__)
    {:ok, self()}
  end
end
