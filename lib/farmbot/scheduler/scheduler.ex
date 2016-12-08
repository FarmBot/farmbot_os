defmodule Farmbot.Scheduler do
  @tick_interval 1500
  @log_tag "Scheduler"
  require Logger
  alias Farmbot.Sync.Database.Regimen, as: Regimen
  alias Farmbot.Sync.Database.RegimenItem, as: RegimenItem
  alias Farmbot.Sync.Database.Sequence, as: Sequence
  @moduledoc """
    This module is the scheduler for "events."
    It manages keeping Regimens and FarmEvents (non existant yet) alive
    and manages the execution of Sequences.
  """

  defmodule State do
    defmodule Serializer do
      @moduledoc """
        When all you want is relevant information :tm:
      """
      @type regimen_info ::
      %{regimen: Regimen.t,
        info: %{start_time: DateTime.t,
                 status: State.regimen_flag}}

      @type t :: %__MODULE__{
        process_info: [regimen_info],
        current_sequence: Sequence.t | nil,
        sequence_log: [Sequence.t]}

      defstruct [
        process_info: [],
        current_sequence: nil,
        sequence_log: []
        ]

      @doc """
        Turns a state into something more readable (by the web app)
      """
      @spec serialize(State.t) :: State.Serializer.t
      def serialize(state) do
        regimen_info_list = Enum.map(state.regimens, fn({_pid, regimen, time, _items, flag}) ->
          %{regimen: regimen,
            info: %{start_time: time,
                    status: flag}}
        end)
        cs = case state.current_sequence do
          {_, sequence} -> sequence
          uh -> uh
        end
          %__MODULE__{process_info: regimen_info_list,
                      current_sequence: cs,
                      sequence_log: state.sequence_log}
      end

    end

    @typedoc """
      :normal or :paused
    """
    @type regimen_flag :: :normal | :paused

    @typedoc """
      pid              is the pis of the running vm instance for this regimen
      regimen          is the actual regimen object.
      [finished_items] is a list of items that have already finished.
      start_time       is midnight of the day that this regimen originally started.
      regimen_flag     is a flag of state of the regimen.
    """
    @type reg_tup :: {pid,Regimen.t, [RegimenItem.t], DateTime.t, regimen_flag}
    @type regimen_list :: list(reg_tup)
    @type sequence_list :: list(Sequence.t)
    @type t :: %__MODULE__{
      regimens: regimen_list,
      current_sequence: {pid, Sequence.t} | nil | :e_stop,
      sequence_log: sequence_list
    }

    defstruct [
      regimens: [],
      current_sequence: nil,
      sequence_log: []
    ]
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    tick
    {:ok, load}
  end

  def tick do
    Process.send_after(__MODULE__, :tick, @tick_interval)
  end

  @spec load :: State.t
  def load do
    default_state = %State{}
    __MODULE__ |> SafeStorage.read |> what_is_it(default_state)
  end

  @spec what_is_it({:ok, State.t}, State.t) :: State.t
  defp what_is_it({:ok, %State{} = last_state}, _default_state) do
    Logger.debug ">> is loading an old Scheduler state: #{inspect last_state}"
    new_state = Map.update!(last_state, :regimens, fn(old_regimens) ->
      Enum.map(old_regimens, fn({_,regimen, finished_items, time, _}) ->
        {:ok, pid} = Scheduler.Regimen.VM.start_link(regimen, finished_items, time)
        {pid,regimen, finished_items, time, :normal}
      end)
    end)
    save_and_update(new_state)
    new_state
  end

  @spec what_is_it(any, State.t) :: State.t
  defp what_is_it(_,default_state), do: default_state

  def handle_cast(:e_stop_lock, state) do
    Logger.warn ">> is stopping the scheduler!"

    # if there is a sequence running, stop it agressivly
    case state.current_sequence do
      {pid, sequence} ->
        Logger.debug ">> is stopping sequence: #{sequence.name}"
        GenServer.stop(pid, :e_stop)
      nil -> nil
      # i have to put this here because the lazy hack of putting
      # :e_stop in the current_sequence feild.
      _ -> nil
    end

    # tell all the regimens to pause.
    Enum.each(state.regimens, fn({pid, _regimen, _items, _start_time, _flag}) ->
      Logger.warn ">> is pausing all running regimens."
      GenServer.cast(pid, :pause)
    end)
    # change current_sequence to something that is not a list or nil
    # so that sequences from the log wont continue to run and
    # crash all over the place.
    {:noreply, %State{state | current_sequence: :e_stop}}
  end

  def handle_cast(:e_stop_unlock, state) do
    Logger.debug ">> is resuiming scheduler.", channels: [:toast], type: :success
    # tell all the regimens to resume.
    # Maybe a problem? the user might not want to restart EVERY regimen
    # there might have been regimens that werent paused by e stop?
    Enum.each(state.regimens, fn({pid, _regimen, _items, _start_time, _flag}) ->
      GenServer.cast(pid, :resume)
    end)
    # set current sequence to nil to allow sequences to continue.
    {:noreply, %State{state | current_sequence: nil}}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add, {:sequence, sequence}}, _from, state) do
    {:reply, :ok, %State{state | sequence_log: state.sequence_log ++ [sequence]}}
  end

  # add a new regimen
  def handle_call({:add, {:regimen, regimen}}, _from, state) do
    current = state.regimens
    # We need to check if it is already started
    case find_regimen(regimen, state.regimens) do
      # If we couln't find this regimen in the list.
      nil ->
        # get the current time (in this timezone)
        now = Timex.now(Farmbot.BotState.get_config(:timezone))

        # shift the current time into midnight of today
        start_time = Timex.shift(now, hours: -now.hour, minutes: -now.minute, seconds: -now.second)
        {:ok, pid} = Scheduler.Regimen.VM.start_link(regimen, [], start_time)
        reg_tup = {pid, regimen, [], start_time, :normal}
        new_state = %State{state | regimens: current ++ [reg_tup]}
        save_and_update(new_state)
        {:reply, :starting, new_state}

      # If the regimen is in paused state.
      {_pid, ^regimen, _finished_items, _start_time, :paused} ->
        #TODO: Restart paused regimens.
        Logger.warn " restarting a paused regimen is not workin yet."
        {:reply, :todo, state}

      # If the regimen is already running.
      {_pid, ^regimen, _finished_items, _start_time, :normal} ->
        Logger.warn ">> has detected that regimen.name is already running!"
        {:reply, :already_started, state}
    end
  end

  # The Sequence finished. Cleanup if its still alive..
  def handle_info({:done, {:sequence, pid, _sequence}}, state) do
    GenServer.stop(pid, :normal)
    new_state = %State{state | current_sequence: nil}
    save_and_update(new_state)
    {:noreply, new_state}
  end

  # A regimen is ready to be stopped.
  def handle_info({:done, {:regimen, pid, regimen}}, state) do
    Logger.debug ">> has completed a regimen: #{regimen.name}."
    reg_tup = find_regimen(regimen, state.regimens)
    new_state = %State{state | regimens: state.regimens -- [reg_tup]}
    save_and_update(new_state)
    GenServer.stop(pid, :normal)
    {:noreply, new_state}
  end

  # a regimen has changed state, and the scheduler needs to know about it.
  # TODO: this is too complex and i hate cond()
  @lint false
  def handle_info({:update, {:regimen,
      {pid, regimen, finished_items, start_time, flag}}}, state)
  do
    # find the index of this regimen in the list.
    found = Enum.find_index(state.regimens, fn({_,cregimen, _,_,_}) ->
      regimen == cregimen
    end)
    cond do
      is_integer(found) ->
        new_state = %State{state | regimens: List.update_at(state.regimens, found,
        fn({^pid, ^regimen, _old_items, ^start_time, _flag}) ->
          {pid, regimen, finished_items, start_time, flag}
        end)}
        save_and_update(new_state)
        {:noreply, new_state}
      is_nil(found) ->
        Logger.error ">> could not find #{regimen.name} in scheduler."
        {:noreply, state}
      true ->
        Logger.error """
          >> encountered something weird happened
          adding updating #{regimen.name} in scheduler.
          """
    end
  end

  # if we are in e_stop mode just wait
  def handle_info(:tick, %State{current_sequence: :e_stop} = state) do
    tick
    {:noreply, state}
  end

  # Tick when the log is empty, ther is no running sequence.
  def handle_info(:tick, %State{sequence_log: [],
                                current_sequence: nil,
                                regimens: regimens})
  do
    tick
    {:noreply, %State{sequence_log: [],
                      current_sequence: nil,
                      regimens: regimens}}
  end

  # Tick when there is a sequence running already.
  def handle_info(:tick, %State{sequence_log: log,
                                current_sequence: {pid, sequence},
                                regimens: regimens})
  do
    tick
    {:noreply, %State{sequence_log: log,
                      current_sequence: {pid, sequence},
                      regimens: regimens}}
  end

  # Tick when there is not a sequence running already.
  def handle_info(:tick, %State{sequence_log: log,
                                current_sequence: nil,
                                regimens: regimens})
  do
    sequence = List.first(log)
    {:ok, pid} = Farmbot.Scheduler.Sequence.Manager.start_link(sequence)
    tick
    {:noreply, %State{sequence_log: log -- [sequence],
                      current_sequence: {pid, sequence},
                      regimens: regimens}}
  end

  def handle_info(:tick, state) do
    Logger.error ">> got an unhandled tick in scheduler: #{inspect state}"
  end

  @doc """
    I CAN'T THINK OF A BETTER WAY TO DO THIS IM SORRY
  """
  @spec save_and_update(State.t) :: :ok
  def save_and_update(%State{} = state) do
    GenServer.cast(Farmbot.BotState.Monitor,
            State.Serializer.serialize(state))
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
  end

  @doc """
    Finds a regimen in the list.
  """
  @spec find_regimen(Regimen.t, State.regimen_list) :: State.reg_tup
  def find_regimen(%Regimen{} = regimen, list)
  when is_list(list) do
    Enum.find(list, fn({_, list_regimen, _, _, _}) ->
      list_regimen == regimen
    end)
  end

  @spec add_sequence(Sequence.t) :: :ok
  def add_sequence(%Sequence{} = sequence) do
    Logger.debug ">> is adding sequence: #{sequence.name}"
    GenServer.call(__MODULE__, {:add, {:sequence, sequence}})
  end

  @doc """
    Add/start a new regimen.
  """
  @spec add_regimen(Regimen.t) :: :ok
  def add_regimen(regimen) do
    Logger.debug ">> is adding a regimen: #{regimen.name}"
    GenServer.call(__MODULE__, {:add, {:regimen, regimen}})
  end

  @doc """
    Gets the current state of Farmbot.Scheduler.
  """
  @spec get_state() :: Farmbot.Scheduler.State.t
  def get_state do
    GenServer.call(__MODULE__, :state)
  end

  @doc """
    Safely E stops things that need to be E stopped.
  """
  @spec e_stop_lock :: :ok
  def e_stop_lock do
    GenServer.cast(__MODULE__, :e_stop_lock)
  end

  @spec e_stop_unlock :: :ok
  def e_stop_unlock do
    GenServer.cast(__MODULE__, :e_stop_unlock)
  end

  def terminate(:normal, _state) do
    Logger.error "Scheduler died unexpectedly."
  end

  # if the scheduler dies for a non normal reason
  # We need to make sure to clean up.
  # if a sequence is running make sure to stop it.
  # stop all regimens so they are not orphaned.
  def terminate(reason, state) do
    Logger.error "scheduler died unexpectedly: #{inspect reason}"
    # stop a sequence if one is running
    case state.current_sequence do
      {pid, _} -> GenServer.stop(pid, :e_stop)
      nil -> nil
      # i have to put this here because the lazy hack of putting
      # :e_stop in the current_sequence feild.
      _ -> nil
    end

    # Stop running regimens
    Enum.each(state.regimens, fn({pid,_,_,_,_}) ->
      GenServer.stop(pid, :e_stop)
    end)
  end
end
