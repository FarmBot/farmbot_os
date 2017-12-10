defmodule Farmbot.FarmEvent.Manager do
  @moduledoc """
  Manages execution of FarmEvents.

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

  # credo:disable-for-this-file Credo.Check.Refactor.FunctionArity

  use GenServer
  use Farmbot.Logger
  alias Farmbot.FarmEvent.Execution
  alias Farmbot.Repo.FarmEvent

  @checkup_time 20_000

  def wait_for_sync do
    GenServer.call(__MODULE__, :wait_for_sync, :infinity)
  end

  def resume do
    GenServer.call(__MODULE__, :resume)
  end

  ## GenServer

  defmodule State do
    @moduledoc false
    defstruct [timer: nil, last_time_index: %{}, wait_for_sync: true]
  end

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:ok, struct(State)}
  end

  def handle_call(:wait_for_sync, _, state) do
    if state.timer do
      Process.cancel_timer(state.timer)
    end
    Logger.busy 3, "Pausing FarmEvent Execution until sync."
    {:reply, :ok, %{state | wait_for_sync: true}}
  end

  def handle_call(:resume, _, state) do
    send self(), :checkup
    Logger.success 3, "Resuming FarmEvents."
    {:reply, :ok, %{state | wait_for_sync: false}}
  end

  def handle_info(:checkup, %{wait_for_sync: true} = state) do
    Logger.warn 3, "Waiting for sync before running FarmEvents."
    {:noreply, state}
  end

  def handle_info(:checkup, %{wait_for_sync: false} = state) do
    now = get_now()

    all_events = Farmbot.Repo.current_repo().all(Farmbot.Repo.FarmEvent)

    # do checkup is the bulk of the work.
    {late_events, new} = do_checkup(all_events, now, state)

    #TODO(Connor) Conditionally start events based on some state info.
    unless Enum.empty?(late_events) do
      Logger.info 3, "Time for event to run at: #{now.hour}:#{now.minute}"
      start_events(late_events, now)
    end

    # Start a new timer.
    timer = Process.send_after self(), :checkup, @checkup_time
    {:noreply, %{new | timer: timer}}
  end

  defp do_checkup(list, time, late_events \\ [], state)

  defp do_checkup([], _now, late_events, state), do: {late_events, state}

  defp do_checkup([farm_event | rest], now, late_events, state) do
    # new_late will be a executable event (Regimen or Sequence.)
    {new_late_event, last_time} = check_event(farm_event, now, state.last_time_index[farm_event.id])

    # update state.
    new_state = %{state | last_time_index: Map.put(state.last_time_index, farm_event.id, last_time)}
    case new_late_event do
      # if `new_late_event` is nil, don't accumulate it.
      nil   -> do_checkup(rest, now, late_events, new_state)
      # if there is a new event, accumulate it.
      event -> do_checkup(rest, now, [event | late_events], new_state)
    end
  end

  defp check_event(%FarmEvent{} = f, now, last_time) do
    # Get the executable out of the database this may fail.
    # mod_list = ["Farmbot", "Repo", f.executable_type]
    mod      = Module.safe_concat([f.executable_type])

    event    = lookup(mod, f.executable_id)

    # build a local start time and end time
    start_time = Timex.parse! f.start_time, "{ISO:Extended}"
    end_time   = Timex.parse! f.end_time,   "{ISO:Extended}"
    # start_time = f.start_time
    # end_time = f.end_time
    # get local bool of if the event is started and finished.
    started?  = Timex.after? now, start_time
    finished? = Timex.after? now, end_time

    case f.executable_type do
      "Elixir.Farmbot.Repo.Regimen"  -> maybe_start_regimen(started?, start_time, last_time, event, now)
      "Elixir.Farmbot.Repo.Sequence" -> maybe_start_sequence(started?, finished?, f, last_time, event, now)
    end
  end

  defp maybe_start_regimen(started?, start_time, last_time, event, now)
  defp maybe_start_regimen(true = _started?, start_time, last_time, event, now) do
    case is_too_old?(now, start_time) do
      true  ->
        # Logger.debug 3, "regimen #{event.name} (#{event.id}) is too old to start or already started."
        {nil, last_time}
      false ->
        # Logger.debug 3, "regimen #{event.name} (#{event.id}) starting."
        {event, now}
    end
  end

  defp maybe_start_regimen(false = _started?, _start_time, last_time, _event, _) do
    # Logger.debug 3, "regimen #{event.name} (#{event.id}) is not started yet. (#{inspect start_time}) (#{inspect Timex.now()})"
    {nil, last_time}
  end

  defp lookup(module, sr_id) do
    case Farmbot.Repo.current_repo().get(module, sr_id) do
      nil -> raise "Could not find #{module} by id: #{sr_id}"
      item -> item
    end
  end

  # signals the start of a sequence based on the described logic.
  defp maybe_start_sequence(started?, finished?, farm_event, last_time, event, now)

  # We only want to check if the sequence is started, and not finished.
  defp maybe_start_sequence(true = _started?, false = _finished?, farm_event, last_time, event, now) do
    {run?, next_time} = should_run_sequence?(farm_event.calendar, last_time, now)
    case run? do
      true  -> {event, next_time}
      false -> {nil, last_time}
    end
  end

  # if `farm_event.time_unit` is "never" we can't use the `end_time`.
  # if we have no `last_time`, time to execute.
  defp maybe_start_sequence(true = _started?, _, %{time_unit: "never"} = f, nil = _last_time, event, now) do
    # Logger.debug 3, "Ignoring end_time."
    case should_run_sequence?(f.calendar, nil, now) do
      {true, next} -> {event, next}
      {false,   _} -> {nil,    nil}
    end
  end

  # if started is false, the event isn't ready to be executed.
  defp maybe_start_sequence(false = _started?, _fin, _farm_event, last_time, _event, _now) do
    # Logger.debug 3, "sequence #{event.name} (#{event.id}) is not started yet."
    {nil, last_time}
  end

  # if the event is finished (but not a "never" time_unit), we don't execute.
  defp maybe_start_sequence(_started?, true = _finished?, _farm_event, last_time, event, _now) do
    Logger.success 3, "sequence #{event.name} (#{event.id}) is finished."
    {nil, last_time}
  end

  # Checks  if we shoudl run a sequence or not. returns {event | nil, time | nil}
  defp should_run_sequence?(calendar, last_time, now)

  # if there is no last time, check if time is passed now within 60 seconds.
  defp should_run_sequence?([first_time | _], nil, now) do

    # Logger.debug 3, "Checking sequence event that hasn't run before #{first_time}"
    # convert the first_time to a DateTime
    dt = Timex.parse! first_time, "{ISO:Extended}"
    # if now is after the time, we are in fact late
    if Timex.after?(now, dt) do
        {true, now}
     else
       # make sure to return nil as the last time because it stil hasnt executed yet.
      #  Logger.debug 3, "Sequence Event not ready yet."
      {false, nil}
    end
  end

  defp should_run_sequence?(nil, last_time, now) do
    # Logger.debug 3, "Checking sequence with no calendar."
    if is_nil(last_time) do
      {true, now}
    else
      {false, last_time}
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
          # Logger.debug 3, "Sequence Event not ready yet."
          {false, dt}
        end
      [] ->
        # Logger.debug 3, "No items in calendar."
        {false, last_time}
    end
  end

  # Enumeration is complete.
  defp start_events([], _now), do: :ok

  # Enumerate the events to be started.
  defp start_events([event | rest], now) do
    # Spawn to be non blocking here. Maybe link to this process?
    spawn fn() -> Execution.execute_event(event, now) end
    # Continue enumeration.
    start_events(rest, now)
  end

  # is then more than 1 minute in the past?
  defp is_too_old?(now, then) do
    # time_str_fun = fn(dt) -> "#{dt.hour}:#{dt.minute}:#{dt.second}" end
    seconds = DateTime.to_unix(now, :second) - DateTime.to_unix(then, :second)
    c = seconds > 60 # not in MS here
    # Logger.debug 3, "is checking #{time_str_fun.(now)} - #{time_str_fun.(then)} = #{seconds} seconds ago. is_too_old? => #{c}"
    c
  end

  defp get_now(), do: Timex.now()
end
