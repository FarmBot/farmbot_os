defmodule StateDebugger do
  @moduledoc false
  use GenEvent
  def handle_event({:dispatch, state},_) do
    {:ok, state}
  end

  def handle_call(:state, state) do
    {:ok, state, state}
  end

  def state do
    GenEvent.call(BotStateEventManager, __MODULE__, :state)
  end

  def start do
    Farmbot.BotState.Monitor.add_handler(__MODULE__)
    {:ok, self()}
  end
end
