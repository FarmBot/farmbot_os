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
    * if there is only one event in the calendar, ignore the `end_time`
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
          |> Enum.map(fn(%{body: actual}) -> actual end)

      # debug_log "BEGIN CHECKUP"
      {late_events, new} = do_checkup(context, all_events, now, state)
      # debug_log "\r\n =======================\r\n"
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
    spawn fn() ->
      execute_event(event, context, now)
    end
    start_events(context, rest, now)
  end

  @spec get_now :: DateTime.t
  defp get_now, do: Timex.now()

  # is then more than 1 minute in the past?
  defp is_too_old?(now, then) do
    blah = fn(dt) -> "#{dt.hour}:#{dt.minute}:#{dt.second}" end
    seconds = DateTime.to_unix(now, :second) - DateTime.to_unix(then, :second)
    c = seconds > 60 # not in MS here
    debug_log "is checking #{blah.(now)} - #{blah.(then)} = #{seconds} seconds ago. is_too_old? => #{c}"
    # require IEx; IEx.pry
    c
  end

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

    debug_log "#{inspect event} starts: #{inspect start_time} | ends: #{inspect end_time} | started? #{started?} | finished? #{finished?}"

    case f.executable_type do
      "Regimen"  -> maybe_start_regimen(started?, start_time, last_time, event, now)
      "Sequence" -> maybe_start_sequence(started?, finished?, f, last_time, event, now)
    end
  end


  # We only want to start the regiment if it is started, and not older than a minute.
  defp maybe_start_regimen(started?, start_time, last_time, event, now)
  defp maybe_start_regimen(_started? = true, start_time, last_time, event, now) do
    case is_too_old?(now, start_time) do
      true  ->
        debug_log "#{inspect event} is too old to start."
        {nil, last_time}
      false ->
        debug_log "#{inspect event} not to old; starting."
        {event, now}
    end
  end

  defp maybe_start_regimen(_started? = false, _start_time, last_time, event, _) do
    debug_log "#{inspect event} is not started yet."
    {nil, last_time}
  end

  # We only want to check if the sequence is started, and not finished.
  defp maybe_start_sequence(started?, finished?, farm_event, last_time, event, now)

  defp maybe_start_sequence(_started? = true, _finished? = false, farm_event, last_time, event, now) do
    {run?, next_time} = should_run_sequence?(farm_event.calendar, last_time, now)
    case run? do
      true  -> {event, next_time}
      false -> {nil, last_time}
    end
  end

  # if `farm_event.time_unit` is "never" we can't use the `end_time`.
  # if we have no `last_time`, time to execute.
  defp maybe_start_sequence(true, _, %{time_unit: "never"} = f, _last_time = nil, event, now) do
    debug_log "Ignoring end_time."
    case should_run_sequence?(f.calendar, nil, now) do
      {true, next} -> {event, next}
      {false,   _} -> {nil,   nil }
    end
  end

  defp maybe_start_sequence(_started? = false, _fin, _farm_event, last_time, event, _now) do
    debug_log "#{inspect event} is not started yet."
    {nil, last_time}
  end

  defp maybe_start_sequence(_started?, _finished? = true, _farm_event, last_time, event, _now) do
    debug_log "#{inspect event} is finished."
    {nil, last_time}
  end

  defp should_run_sequence?(calendar, last_time, now)

  # if there is no last time, check if time is passed now within 60 seconds.
  defp should_run_sequence?([first_time | _], nil, now) do
    debug_log "Checking sequence event that hasn't run before."
    # convert the first_time to a DateTime
    dt = Timex.parse! first_time, "{ISO:Extended}"
    # if now is after the time, we are in fact late
    if Timex.after?(now, dt) do
        {true, now}
     else
       # make sure to return nil as the last time because it stil hasnt executed yet.
       debug_log "Sequence Event not ready yet."
      {false, nil}
    end
  end

  defp should_run_sequence?(calendar, last_time, now) do
    # get rid of all the items that happened before last_time
    filtered_calendar = Enum.filter(calendar, fn(iso_time) ->
      dt = Timex.parse! iso_time, "{ISO:Extended}"
      # we only want this time if it happened after the last_time
      Timex.after?(dt, last_time)
    end)

    # if after filtering, there are events that need to be run
    # check if they are older than a minute ago,
    case filtered_calendar do
      [iso_time |  _] ->
        dt = Timex.parse! iso_time, "{ISO:Extended}"
        if Timex.after?(now, dt) do
          {true, dt}
          # too_old? = is_too_old?(now, dt)
          # if too_old?, do: {false, last_time}, else: {true, dt}
        else
          debug_log "Sequence Event not ready yet."
          {false, dt}
        end
      [] ->
        debug_log "No items in calendar."
        {false, last_time}
    end

  end

  @spec lookup(Context.t, Sequence | Regimen, integer) :: Sequence.t | Regimen.t | no_return
  defp lookup(%Context{} = ctx, module, sr_id) do
    item = Database.get_by_id(ctx, module, sr_id)
    unless item do
      raise "Could not find #{inspect module} by id: #{sr_id}"
    end

    item.body
  end
end
