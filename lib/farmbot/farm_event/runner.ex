defmodule Farmbot.FarmEvent.Runner do
  @moduledoc """
  Checks the database every 20 seconds for FarmEvents

  ## Rules for FarmEvent execution.
  * Regimen
    * ignore `end_time`.
    * ignore calendar.
    * if start_time is more than 60 seconds passed due, assume it already started, and don't start it again.
  * Sequence
    * if `start_time` is late, check the calendar.
      * for each item in the calendar, check if it's event is more than 60 seconds in the past. if not, execute it.
  """
  require Logger
  alias   Farmbot.{Context, DebugLog, Database}
  import  Farmbot.FarmEvent.Executer
  use     DebugLog
  use     GenServer
  alias   Database.Syncable.{
    Sequence,
    Regimen,
    FarmEvent
  }

  @checkup_time 20_000

  @type database :: Database.db
  @type state :: {database, %{required(integer) => DateTime.t}}

  def start_link(%Context{} = context, opts) do
    GenServer.start_link(__MODULE__, context, opts)
  end

  def init(%{database: db} = context) when is_pid(db) do
    Process.link(db)
    Database.hook(context, self())
    send self(), :checkup
    {:ok, {context, nil, %{} }}
  end

  def init(%{database: db} = context) when is_atom(db) do
    db_pid = Process.whereis(db) || raise "Could not find Database pid."
    init(%{context | database: db_pid})
  end

  def handle_info({Database, :sync_start}, {context, timer, state}) do
    debug_log "Pausing FarmEvent runner until sync finishes."
    if timer do
      Process.cancel_timer(timer)
    end
    {:noreply, {context, nil, state}}
  end

  def handle_info({Database, :sync_end}, {context, timer, state}) do
    debug_log "Resuming FarmEvent runner."
    if timer do
      Process.cancel_timer(timer)
    end
    new_timer = Process.send_after self(), :checkup, @checkup_time
    {:noreply, {context, new_timer, state}}
  end

  def handle_info({Database, _}, state), do: {:noreply, state}

  def handle_info(:checkup, {context, _, state}) do
    now = get_now()
    # debug_log "Doing checkup: #{inspect now}"
    new_state = if now do
      all_events =
        context
          |> Database.get_all(FarmEvent)
          |> Enum.map(fn(db_object) -> db_object.body end)
      debug_log "BEGIN CHECKUP"
      {late_events, new} = do_checkup(context, all_events, now, state)
      debug_log "\r\n =======================\r\n"
      unless Enum.empty?(late_events) do
        Logger.info "Time for event to run at: #{now.hour}:#{now.minute}"
        start_events(context, late_events, now)
      end
      new
    else
      state
    end
    timer = Process.send_after self(), :checkup, @checkup_time
    {:noreply, {context, timer, new_state}}
  end

  @spec start_events(Context.t, [Sequence.t | Regimen.t], DateTime.t)
    :: no_return
  defp start_events(_context, [], _now), do: :ok
  defp start_events(%Context{} = context, [event | rest], now) do
    execute_event(event, context, now)
    start_events(context, rest, now)
  end

  def terminate(reason, _fe) do
    Logger.error "Farm Event Runner died. #{inspect reason}"
  end

  @spec get_now :: DateTime.t
  defp get_now, do: Timex.now()

  @type late_event :: Regimen.t | Sequence.t
  @type late_events :: [late_event]

  # TODO(Connor) turn this into tasks
  # NOTE(Connor) yes i could have just done an Enum.reduce here, but i want
  # it to be async at some point
  @spec do_checkup(Context.t, [struct], DateTime.t, late_events, state)
    :: {late_events, state}
  defp do_checkup(context, list, time, late_events \\ [], state)

  defp do_checkup(_, [], _now, late_events, state), do: {late_events, state}

  defp do_checkup(%Context{} = ctx,
    [farm_event | rest], now, late_events, state)
  do
    {new_late, last_time} = check_event(ctx,
      farm_event, now, state[farm_event.id])

    new_state = Map.put(state, farm_event.id, last_time)
    if new_late do
      do_checkup(ctx, rest, now, [new_late | late_events], new_state)
    else
      do_checkup(ctx, rest, now, late_events, new_state)
    end
  end

  @spec check_event(Context.t, FarmEvent.t, DateTime.t, DateTime.t)
    :: {late_event | nil, DateTime.t}
  defp check_event(%Context{} = ctx, %FarmEvent{} = f, now, last_time) do
    # Get the executable out of the database this may fail.
    mod_list = [Farmbot.Database, Syncable, f.executable_type |> String.to_atom]
    mod      = Module.safe_concat(mod_list)
    event    = lookup(ctx, mod, f.executable_id)

    # build a local start time and end time
    start_time = Timex.parse! f.start_time, "{ISO:Extended}"
    end_time   = Timex.parse! f.end_time,   "{ISO:Extended}"

    # get local bool of if the event is started and finished.
    started?  = Timex.after? now, start_time
    finished? = Timex.after? now, end_time

    case f.executable_type do
      "Regimen"  ->
        # checks starts time agains now minus one minute.
        too_old? = abd
        # if the event is started and not too_old, it needs to be executed.
        if started? and not too_old?, do: {event, now}, else: {nil, last_time}
      "Sequence" ->
        # if the event was started and not finished yet., we need to enumerate the calendar
        # and check each event against now, the start_time, and the last_time.
        if started? and not finished? do
          {run?, next_time} = should_run_sequence?(f.calendar, last_time, now)
          if run?, do: {event, next_time}, else: {nil, last_time}
        else
          {nil, last_time}
        end
    end
  end

  defp should_run_sequence?(calendar, last_time, now)

  # if there is no last time, check if time is passed now within 60 seconds.
  defp should_run_sequence?([time | _], nil, now) do
    # convert the first_time to a DateTime
    dt = Timex.parse! first_time, "{ISO:Extended}"
    # if now is after the time, we are in fact late
    if Timex.after?(now, dt) do
      # if that time is greater than 60 seconods, this event is _too_ late, or already executed.
      # make sure to return nil as the last time because it stil hasnt executed yet.
      if too_old?, do: {false, nil}, else: {true, now}
     else
      {false, nil}
    end
  end

  defp should_run_sequence?(calendar, last_time, now) do
    # FIXME
  end

  # we are started, not finished, and no last time
  defp should_run_sequence?(true, false, calendar, last_time, now) do
    # get rid of all the items that happened before last_time
    calendar = Enum.filter(calendar, fn(iso_time) ->
      dt = Timex.parse! iso_time, "{ISO:Extended}"
      # we only want this time if it happened after the last_time
      Timex.after?(dt, last_time)
    end)

    _f = Enum.map(calendar, fn(item) ->
      item
      |> Timex.parse!("{ISO:Extended}")
      |> Timex.format!("{relative}", :relative)
    end)

    print_debug_info(last_time, now, calendar)

    case calendar do
      [iso_time |  _] ->
        dt = Timex.parse! iso_time, "{ISO:Extended}"
        if Timex.after?(now, dt), do: {true, dt}, else: {false, last_time}
      [] -> {false, last_time}
    end
  end

  defp print_debug_info(last_time, now, calendar) do
    now_str = now |> Timex.format!("{relative}", :relative)
    last_time_str = get_last_time_str(last_time)
    c_item = List.first(calendar)
    get_next_str(c_item)

    maybe_next_str =
    debug_log "== NOW: #{inspect now_str}"
    debug_log "== LAST: #{inspect last_time_str}"
    debug_log "== MAYBE NEXT: #{inspect maybe_next_str}"
    debug_log "== #{Enum.count calendar} events are scheduled to happen after: #{inspect last_time_str}\n"
  end

  defp get_last_time_str(nil), do: "none"
  defp get_last_time_str(last_time) do
    Timex.format!(last_time, "{relative}", :relative)
  end

  defp get_next_str(nil), do: "none"
  defp get_next_str(c_item) do
    c_item
    |> Timex.parse!("{ISO:Extended}")
    |> Timex.format!("{relative}", :relative)
  end

  @spec lookup(Context.t, Sequence | Regimen, integer) :: Sequence.t | Regimen.t
  defp lookup(%Context{} = ctx, module, sr_id) do
    item = Database.get_by_id(ctx, module, sr_id)
    unless item do
      raise "Could not find #{inspect module} by id: #{sr_id}"
    end

    item.body
  end
end
