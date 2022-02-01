defmodule FarmbotOS.AssetMonitor do
  @moduledoc """
  Handles starting a process for every Asset in the repo requiring an
  AssetWorker implementation.
  """

  use GenServer
  import FarmbotOS.TimeUtils, only: [compare_datetimes: 2]

  alias FarmbotOS.Asset.{
    Repo,
    Device,
    FbosConfig,
    FirmwareConfig,
    FarmEvent,
    FarmwareEnv,
    Peripheral,
    RegimenInstance,
    PinBinding
  }

  alias FarmbotOS.{ChangeSupervisor, AssetWorker}

  require Logger

  @checkup_time_ms 10000

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    state = Map.new(order(), fn module -> {module, %{}} end)
    state = Map.put(state, :order, order())
    state = Map.put(state, :force_callers, [])
    {:ok, state, 0}
  end

  def handle_info(:timeout, %{order: []} = state) do
    state = %{state | order: order()}

    case state.force_callers do
      [caller | rest] ->
        GenServer.reply(caller, :ok)
        {:noreply, %{state | force_callers: rest}, 0}

      [] ->
        {:noreply, state, @checkup_time_ms}
    end
  end

  def handle_info(:timeout, state) do
    [kind | rest] = state.order
    results = handle_kind(kind, state[kind])
    {:noreply, %{state | kind => results, order: rest}, 0}
  end

  def handle_kind(kind, sub_state) do
    expected = Repo.all(kind)
    expected_ids = Enum.map(expected, &Map.fetch!(&1, :local_id))
    actual_ids = Enum.map(sub_state, fn {local_id, _} -> local_id end)
    deleted_ids = actual_ids -- expected_ids
    sub_state = Map.drop(sub_state, deleted_ids)

    Enum.each(deleted_ids, fn local_id ->
      ChangeSupervisor.terminate_child(kind, local_id)
    end)

    Enum.reduce(expected, sub_state, fn %{local_id: id, updated_at: updated_at} =
                                          asset,
                                        sub_state ->
      cond do
        asset.monitor == false ->
          Map.put(sub_state, id, updated_at)

        is_nil(sub_state[id]) ->
          asset = Repo.preload(asset, AssetWorker.preload(asset))
          :ok = ChangeSupervisor.start_child(asset) |> assert_result!(asset)
          Map.put(sub_state, id, updated_at)

        compare_datetimes(updated_at, sub_state[id]) == :gt ->
          asset = Repo.preload(asset, AssetWorker.preload(asset))
          :ok = ChangeSupervisor.update_child(asset) |> assert_result!(asset)
          Map.put(sub_state, id, updated_at)

        true ->
          sub_state
      end
    end)
  end

  defp assert_result!(:ignore, _), do: :ok
  defp assert_result!({:ok, _}, _), do: :ok
  defp assert_result!({:error, {:already_started, _pid}}, _), do: :ok

  defp assert_result!(result, asset),
    do:
      exit(
        "Failed to start or update child: #{inspect(asset)} #{inspect(result)}"
      )

  def order,
    do: [
      Device,
      FbosConfig,
      FirmwareConfig,
      FarmEvent,
      Peripheral,
      RegimenInstance,
      PinBinding,
      FarmwareEnv
    ]
end
