defmodule Farmbot.Sync.EventManager do
  def start_link, do: GenEvent.start_link(name: __MODULE__)
  def call(handler, thing), do: GenEvent.call(__MODULE__, handler, thing)
end

defmodule Farmbot.Sync.EventHandler do
  require Logger
  def start_link do
    GenEvent.add_handler(Farmbot.Sync.EventManager, __MODULE__, [])
  end

  def init([]) do
    {:ok, []}
  end

  def handle_event({module, map_set}, state) do
    [object | _t] = Module.split(module) |> Enum.reverse
    list = MapSet.to_list(map_set)
    for change <- list do
      Logger.debug ">> detected a #{inspect object} change: #{inspect change}"
    end
    {:ok, state}
  end

  def handle_event(event, state) do
    IO.inspect event
    {:ok, state}
  end
end
