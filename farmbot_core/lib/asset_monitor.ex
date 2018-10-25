defmodule Farmbot.AssetMonitor do
  use GenServer
  import Ecto.Query
  import Farmbot.TimeUtils, only: [compare_datetimes: 2]
  alias Farmbot.Asset.{
    Repo,
    FarmEvent,
    Peripheral,
    PersistentRegimen,
    PinBinding
  }
  require Logger

  @checkup_ms 5_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    state = Map.new(order(), fn(module) -> {module, %{}} end)
    state = Map.put(state, :order, order())
    {:ok, state, 0}
  end

  def handle_info(:timeout, %{order: []} = state) do
    {:noreply, %{state | order: order()}, @checkup_ms}
  end

  def handle_info(:timeout, state) do
    [kind | rest] = state.order
    results = handle_kind(kind, state[kind])
    {:noreply, %{state | kind => results, order: rest}, 0}
  end

  def handle_kind(kind, sub_state) do
    expected = Repo.all(kind)
    expected_ids = Enum.map(expected, &Map.fetch!(&1, :local_id))
    actual_ids = Enum.map(sub_state, fn({local_id, _}) -> local_id end)
    deleted_ids = actual_ids -- expected_ids
    sub_state = Map.drop(sub_state, deleted_ids)
    Enum.each(deleted_ids, fn(local_id) ->
      Logger.error "#{inspect kind} #{local_id} needs to be terminated"
      Farmbot.AssetSupervisor.terminate_child(kind, local_id)
    end)

    Enum.reduce(expected, sub_state, fn(%{local_id: id, updated_at: updated_at} = asset, sub_state) ->
      cond do
        is_nil(sub_state[id]) ->
          Logger.debug "#{inspect kind} #{id} needs to be started"
          Farmbot.AssetSupervisor.start_child(asset)
          Map.put(sub_state, id, updated_at)
        compare_datetimes(updated_at, sub_state[id]) == :gt ->
          Logger.warn "#{inspect kind} #{id} needs to be updated"
          Farmbot.AssetSupervisor.update_child(asset)
          Map.put(sub_state, id, updated_at)
        true ->
          sub_state
      end
    end)

  end

  def order, do: [FarmEvent, Peripheral, PersistentRegimen, PinBinding]
end
