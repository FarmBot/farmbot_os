defimpl Farmbot.AssetWorker, for: Farmbot.Asset.FarmEvent do
  alias Farmbot.{
    Asset,
    Asset.FarmEvent,
    Asset.Regimen,
    Asset.Sequence,
  }

  require Logger
  use GenServer

  defstruct [:farm_event, :executable, :date_time]
  alias __MODULE__, as: State

  @default_checkup_ms 10000

  def delete_me do
    %Sequence{
      id: 1,
      kind: "sequence",
      args: %{},
      body: []
    } |> Farmbot.Asset.Repo.insert()

    now = DateTime.utc_now()
    %FarmEvent{
      id: 100,
      executable_type: "Sequence",
      executable_id: 1,
      repeat: 1,
      start_time: now,
      end_time: now |> Timex.shift(years: 20),
      time_unit: "minutely"
    } |> Asset.Repo.insert!()
  end

  def start_link(farm_event) do
    GenServer.start_link(__MODULE__, [farm_event])
  end

  def init([farm_event]) do
    executable = ensure_executable!(farm_event)
    now = DateTime.utc_now()
    state = %State{
      farm_event: farm_event,
      executable: executable,
      date_time: farm_event.last_executed || DateTime.utc_now()
    }
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
    raise("fixme")
    wakeup_ms = Timex.compare(state.farm_event.start_time, now, :milliseconds)
    {:ok, state, wakeup_ms}
  end

  defp init_event_completed(_, _) do
    Logger.warn "No future events"
    :ignore
  end

  def init_event_started(%State{} = state, _now) do
    {:ok, state, 0}
  end

  def handle_info(:timeout, %State{} = state) do
    Logger.info "build_calendar"
    next = FarmEvent.build_calendar(state.farm_event, state.date_time)

    if next do
      # positive if the first date/time comes after the second.
      diff = DateTime.compare(next, DateTime.utc_now())
      # if next_event is more than 0 milliseconds away, schedule that event.
      case diff do
        :gt ->
          Logger.info "Event is still in the future"
          {:noreply, state, @default_checkup_ms}
        diff when diff in [:lt, :eq] ->
          Logger.info "Event should be executed:  #{Timex.from_now(next)}"
          event = ensure_executed!(state.farm_event, state.executable, next)
          {:noreply, %{state | farm_event: event, date_time: DateTime.utc_now()}, @default_checkup_ms}
      end

    else
      Logger.warn "No more future events to execute."
      {:stop, :normal, state}
    end
  end

  defp ensure_executed!(%FarmEvent{last_executed: nil} = event, %Sequence{} = exe, next_dt) do
    # positive if the first date/time comes after the second.
    comp = Timex.compare(DateTime.utc_now(), next_dt, :minutes)
    cond do
      # now is more than 2 minutes past expected execution time
      comp > 2 ->
        Logger.warn "Sequence: #{inspect exe} too late."
        event
      true ->
        Logger.warn "Sequence: #{inspect exe} has not run before: #{comp} minutes difference."
        Asset.update_farm_event!(event, %{last_executed: next_dt})
    end
  end

  defp ensure_executed!(%FarmEvent{} = event, %Sequence{} = exe, next_dt) do
    # positive if the first date/time comes after the second.
    case Timex.compare(event.last_executed, next_dt, :minutes) do
      a >  ->
        Logger.warn("Sequence: #{inspect exe} needs executing")
        Asset.update_farm_event!(event, %{last_executed: next_dt})
      0 ->
        Logger.warn("Sequence: #{inspect exe} already executed: #{Timex.from_now(next_dt)}")
        event
    end
  end

  defp ensure_executed!(%FarmEvent{last_executed: nil} = event, %Regimen{} = exe, next_dt) do
    Logger.warn "Regimen: #{inspect exe} has not run before. Executing it."
    Asset.update_farm_event!(event, %{last_executed: next_dt})
  end

  defp ensure_executed!(%FarmEvent{} = event, %Regimen{} = exe, next_dt) do
    case DateTime.compare(event.last_executed, next_dt) do
      :gt -> raise("Last executed in the future?")
      :lt ->
        Logger.warn("Regimen: #{inspect exe} needs executing")
        Asset.update_farm_event!(event, %{last_executed: next_dt})
      :eq ->
        Logger.warn("Regimen: #{inspect exe} already executed")
        event
    end
  end

  defp ensure_executable!(%FarmEvent{executable_type: "Sequence", executable_id: id}) do
    Asset.get_sequence!(id)
  end

  defp ensure_executable!(%FarmEvent{executable_type: "Regimen", executable_id: id}) do
    Asset.get_regimen!(id)
  end
end
