defimpl Farmbot.AssetWorker, for: Farmbot.Asset.FarmEvent do
  alias Farmbot.{
    Asset,
    Asset.FarmEvent,
    Asset.Regimen,
    Asset.Sequence,
  }

  require Logger
  use GenServer

  defstruct [:farm_event, :date_time]
  alias __MODULE__, as: State

  @checkup_time_ms Application.get_env(:farmbot_core, __MODULE__)[:checkup_time_ms]
  @checkup_time_ms || Mix.raise("""
  config :farmbot_core, #{__MODULE__}, checkup_time_ms: 10_000
  """)

  def start_link(farm_event) do
    GenServer.start_link(__MODULE__, [farm_event])
  end

  def init([farm_event]) do
    ensure_executable!(farm_event)
    now = DateTime.utc_now()
    state = %State{
      farm_event: farm_event,
      date_time: farm_event.last_executed || DateTime.utc_now()
    }
    # check if now is _before_ start_time
    case DateTime.compare(now, farm_event.start_time) do
      :lt -> init_event_started(state, now)
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
          {:noreply, state, @checkup_time_ms}
        diff when diff in [:lt, :eq] ->
          Logger.info "Event should be executed:  #{Timex.from_now(next)}"
          executable = ensure_executable!(state.farm_event)
          event = ensure_executed!(state.farm_event, executable, next)
          {:noreply, %{state | farm_event: event, date_time: DateTime.utc_now()}, @checkup_time_ms}
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
        Farmbot.Core.CeleryScript.sequence(exe, fn(_) -> :ok end)
        Asset.update_farm_event!(event, %{last_executed: next_dt})
    end
  end

  defp ensure_executed!(%FarmEvent{} = event, %Sequence{} = exe, next_dt) do
    # positive if the first date/time comes after the second.
    comp = Timex.compare(event.last_executed, :minutes)
    cond do
      comp > 2 ->
        Logger.warn("Sequence: #{inspect exe} needs executing")
        Farmbot.Core.CeleryScript.sequence(exe, fn(_) -> :ok end)
        Asset.update_farm_event!(event, %{last_executed: next_dt})
      0 ->
        Logger.warn("Sequence: #{inspect exe} already executed: #{Timex.from_now(next_dt)}")
        event
    end
  end

  defp ensure_executed!(%FarmEvent{last_executed: nil} = event, %Regimen{} = exe, next_dt) do
    Logger.warn "Regimen: #{inspect exe} has not run before. Executing it."
    Asset.upsert_persistent_regimen(exe, event, %{started_at: next_dt})
    Asset.update_farm_event!(event, %{last_executed: next_dt})
  end

  defp ensure_executed!(%FarmEvent{} = event, %Regimen{} = exe, _next_dt) do
    Asset.upsert_persistent_regimen(exe, event)
    event
  end

  defp ensure_executable!(%FarmEvent{executable_type: "Sequence", executable_id: id}) do
    Asset.get_sequence!(id: id)
  end

  defp ensure_executable!(%FarmEvent{executable_type: "Regimen", executable_id: id}) do
    Asset.get_regimen!(id: id)
  end
end
