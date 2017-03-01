defmodule FarmEventRunner do
  @moduledoc """
    Checks the database every 60 seconds for FarmEvents
  """
  use GenServer
  use Amnesia
  use Farmbot.Sync.Database
  require Logger

  @checkup_time 10_000

  @type state :: %{required(integer) => DateTime.t}

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    send self(), :checkup
    {:ok, %{}}
  end

  def handle_info(:checkup, state) do
    now = get_now()
    new_state = if now do
      all_events = Amnesia.transaction do
        Amnesia.Selection.values(FarmEvent.where(true))
        # |> Enum.map(fn(farm_event) ->
        #   # get rid of all the items that happened before last_time
        #   calendar = Enum.filter(farm_event.calendar, fn(iso_time) ->
        #     dt = Timex.parse! iso_time, "{ISO:Extended}"
        #     # we only want this time if it happened after the last_time
        #     Timex.after?(dt, now)
        #   end)
        #   %{farm_event | calendar: calendar}
        # end)
      end
      {late_events, new} = do_checkup(all_events, now, state)
      # IO.inspect all_events
      unless Enum.empty?(late_events) do
        Logger.warn "TIME TO DO STUFF: #{inspect late_events} " <>
          " at: #{now.hour}:#{now.minute}"
        start_events(late_events, now)
      end
      new
    else
      state
    end
    Process.send_after self(), :checkup, @checkup_time
    {:noreply, new_state}
  end

  @spec start_events([Sequence.t | Regimen.t], DateTime.t) :: no_return
  defp start_events([], _now), do: :ok
  defp start_events([event | rest], now) do
    r = event.__struct__
      |> Module.split
      |> List.last
      |> Module.concat(Supervisor)
    {:ok, _pid} = r.add_child(event, now)
    start_events(rest, now)
  end

  def terminate(_reason, _fe) do
    Logger.error "UH OH!"
  end

  @spec get_now :: DateTime.t | nil
  defp get_now do
    Timex.now()
  end

  @type late_event :: Regimen.t | Sequence.t
  @type late_events :: [late_event]

  # TODO(Connor) turn this into tasks
  # NOTE(Connor) yes i could have just done an Enum.reduce here, but i want
  # it to be async at some point
  @spec do_checkup([struct], DateTime.t, late_events, state)
    :: {late_events, state}
  defp do_checkup(list, time, late_events \\ [], state)

  defp do_checkup([], _now, late_events, state), do: {late_events, state}

  defp do_checkup([farm_event | rest], now, late_events, state) do
    {new_late, last_time} = check_event(farm_event, now, state[farm_event.id])
    new_state = Map.put(state, farm_event.id, last_time)
    if new_late do
      do_checkup(rest, now, [new_late | late_events], new_state)
    else
      do_checkup(rest, now, late_events, new_state)
    end
  end

  @spec check_event(FarmEvent.t, DateTime.t, DateTime.t)
    :: {late_event | nil, DateTime.t}
  defp check_event(%FarmEvent{} = f, now, last_time) do
    # Get the executable out of the database
    event =
      [Database, f.executable_type |> String.to_atom]
      |> Module.concat
      |> lookup(f.executable_id)

    # build a local start time
    start_time = Timex.parse! f.start_time, "{ISO:Extended}"

    # is now after the start time?
    started? = Timex.after? now, start_time

    # build a local end_time
    end_time = Timex.parse! f.end_time, "{ISO:Extended}"

    # is now after the end time?
    finished? = Timex.after? now, end_time

    # Check if we need to run, and return the last time we ran
    {run?, last_time} =
      should_run?(started?, finished?, f.calendar, last_time, now)
    if run? do
      {event, last_time}
    else
      {nil, last_time}
    end
  end

  @spec should_run?(boolean, boolean, [String.t], DateTime.t | nil, DateTime.t)
    :: {late_event | nil, DateTime.t | nil}
  defp should_run?(started?, finished?, calendar, last_time, now)

  # if we arent started yet, there wont be any to run
  defp should_run?(false, _, _, last_time, _), do: {nil, last_time}
  # if we ARE finished, doesnt matter
  defp should_run?(_, true, _, last_time, _), do: {nil, last_time}

  # we are started, not finished, and no last time
  defp should_run?(true, false, [first_time | _], nil, now) do
    # convert the first_time to a DateTime
    dt = Timex.parse! first_time, "{ISO:Extended}"
    # if now is after the time, we are in fact late
    if Timex.after?(now, dt) do
      {true, now}
     else
      {false, nil}
    end
  end

  # we are started, not finished, and no last time
  @lint false
  defp should_run?(true, false, calendar, last_time, now) do
    # IO.puts "calendar size: #{Enum.count(calendar)}"
    # IEx.pry
    # get rid of all the items that happened before last_time
    calendar = Enum.filter(calendar, fn(iso_time) ->
      dt = Timex.parse! iso_time, "{ISO:Extended}"
      # we only want this time if it happened after the last_time
      Timex.after?(dt, last_time)
    end)

    _f = Enum.map(calendar, fn(item) -> Timex.parse!(item, "{ISO:Extended}") |> Timex.format!("{relative}", :relative) end)


    # DEBUG
    now_str = now |> Timex.format!("{relative}", :relative)
    last_time_str = if(last_time) do Timex.format!(last_time, "{relative}", :relative) else "none" end
    c_item = List.first(calendar)
    maybe_next_str = if(c_item) do Timex.parse!(c_item, "{ISO:Extended}") |> Timex.format!("{relative}", :relative) else "none" end
    IO.puts "== NOW: #{inspect now_str}"
    IO.puts "== LAST: #{inspect last_time_str}"
    IO.puts "== MAYBE NEXT: #{inspect maybe_next_str}"
    IO.puts "== #{Enum.count calendar} events are scheduled to happend after: #{inspect last_time_str}\n"
    # IO.puts "new calendar size: #{Enum.count(calendar)}"

    # DEBUG

    case calendar do
      [iso_time |  _] ->
        dt = Timex.parse! iso_time, "{ISO:Extended}"
        if Timex.after?(now, dt), do: {true, dt}, else: {false, last_time}
      [] -> {false, last_time}
    end
  end

  # THANKS AMNESIA
  @lint false
  @spec lookup(Sequence | Regimen, integer) :: Sequence.t | Regimen.t
  defp lookup(Sequence, sr_id) do
    [item] = Amnesia.transaction do
      Sequence.where(id == sr_id)
      |> Amnesia.Selection.values
    end
    item
  end

  defp lookup(Regimen, sr_id) do
    [item] = Amnesia.transaction do
      Regimen.where(id == sr_id)
      |> Amnesia.Selection.values
    end
    item
  end
end
