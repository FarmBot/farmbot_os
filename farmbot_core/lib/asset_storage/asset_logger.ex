defmodule Farmbot.Asset.Logger do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    Farmbot.Registry.subscribe()
    {:ok, %{status: :undefined}}
  end

  def handle_info({Farmbot.Registry, {Farmbot.Asset, {:sync_status, status}}}, %{status: status} = state) do
    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, {Farmbot.Asset, {:sync_status, status}}}, state) do
    Logger.debug "Asset sync_status #{state.status} => #{status}"
    {:noreply, %{state | status: status}}
  end

  def handle_info({Farmbot.Registry, {Farmbot.Asset, {action, data}}}, state) do
    Logger.debug "Asset #{action} #{inspect data}"
    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, {_ns, _data}}, state) do
    {:noreply, state}
  end
end
