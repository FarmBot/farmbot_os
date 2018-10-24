defimpl Farmbot.AssetWorker, for: Farmbot.Asset.FarmEvent do
  alias Farmbot.{
    Asset,
    Asset.FarmEvent,
    Asset.Regimen,
    Asset.Sequence,
  }

  require Logger
  use GenServer

  defstruct [:farm_event, :executable, :context]
  alias __MODULE__, as: State

  def delete_me do
    # %Sequence{
    #   id: 1,
    #   kind: "sequence",
    #   args: %{},
    #   body: []
    # } |> Farmbot.Asset.Repo.insert()

    %FarmEvent{
      id: 100,
      local_id: "abc",
      executable_type: "Sequence",
      executable_id: 1,
      repeat: 2,
      start_time: DateTime.utc_now(),
      end_time: DateTime.utc_now() |> Timex.shift(hours: 2),
      time_unit: "minutely"
    }
  end

  def start_link(farm_event) do
    GenServer.start_link(__MODULE__, [farm_event])
  end

  def terminate(reason, state) do
    Logger.error(inspect reason)
    Logger.error(inspect state)
  end

  def init([farm_event]) do
    executable = ensure_executable!(farm_event)
    now = DateTime.utc_now()
    state = %State{farm_event: farm_event, executable: executable, context: :wait}
    # check if now is _before_ start_time
    case DateTime.compare(now, farm_event.start_time) do
      :lt -> init_event_not_started(state, now)
      _ ->
        # check if now is _after_ end_time
        case DateTime.compare(now, farm_event.end_time) do
          :gt -> init_event_completed(state, now)
          _ -> init_event_started(state, now)
        end
    end
  end

  defp init_event_not_started(%State{} = state, now) do
    wakeup_ms = Timex.compare(state.farm_event.start_time, now, :milliseconds)
    {:ok, state, wakeup_ms}
  end

  defp init_event_completed(_, _) do
    Logger.warn "Event past due"
    :ignore
  end

  def init_event_started(%State{} = state, _now) do
    Logger.info "??"
    {:ok, state, 0}
  end

  def handle_info(:timeout, %State{context: :wait} = state) do
    Logger.info "build_calendar"
    calendar = FarmEvent.build_calendar(state.farm_event)
    {:noreply, state, {:continue, calendar}}
  end

  def handle_info(:timeout, %State{context: :schedule} = state) do
    Logger.warn "Time for: #{inspect state.executable} to be scheduled"
    handle_info(:timeout, %{state | context: :wait})
  end

  def handle_continue([next_event | rest], %State{} = state) do
    Logger.info "continue"
    wakeup_ms = Timex.diff(DateTime.utc_now(), next_event, :milliseconds)
    # if next_event is more than 0 milliseconds away, schedule that event.
    if wakeup_ms > 0 do
      # This doesn't work because the value is to big. Need
      # this to be more of a "schedule checkup" maybe?
      Logger.info "Scheduling event to execute in #{wakeup_ms} ms"
      {:noreply, %{state | context: :schedule}, wakeup_ms}
    else
      Logger.info "#{wakeup_ms} not in the future."
      {:noreply, state, {:continue, rest}}
    end
  end

  def handle_continue([], %State{} = state) do
    Logger.info "no more events in calendar."
    {:stop, :normal, state}
  end

  defp ensure_executable!(%FarmEvent{executable_type: "Sequence", executable_id: id}) do
    Asset.get_sequence!(id)
  end

  defp ensure_executable!(%FarmEvent{executable_type: "Regimen", executable_id: id}) do
    Asset.get_regimen!(id)
  end
end
