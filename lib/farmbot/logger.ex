defmodule Farmbot.Logger do
  @moduledoc "Logger."
  use GenStage

  @doc false
  def start_link() do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    Logger.add_backend(Logger.Backends.Farmbot, [])
    {:producer,%{}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(_, state) do
    {:noreply, [], state}
  end

  def handle_events(_, _from, state) do
    {:noreply, [], state}
  end

  def handle_info({:log, log}, state) do
    {:noreply, [log], state}
  end

  def terminate(_, _state) do
    Logger.remove_backend(Logger.Backends.Farmbot)
  end
end
