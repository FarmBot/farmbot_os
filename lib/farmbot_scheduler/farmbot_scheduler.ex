defmodule Farmbot.Scheduler do
  @save_interval 10000
  @tick_interval 1500
  @log_tag __MODULE__
  require Logger
  @moduledoc """
    This module is the scheduler for "events."
    It manages keeping Regimens and FarmEvents (non existant yet) alive
    and manages the execution of Sequences.
  """

  defmodule State do
    @moduledoc false

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
      current_sequence: {pid, Sequence.t} | nil,
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

  @spec load :: Farmbot.Scheduler.State.t
  def load do
    default_state = %State{}
    default_state
  end

  def handle_cast(:e_stop, state) do
    Logger.warn("E stopping TODO in Farmbot Scheduler")

    # if there is a sequence running, stop it agressivly
    case state.current_sequence do
      {pid, _sequence} -> GenServer.stop(pid, :e_stop)
      nil -> nil
    end

    # tell all the regimens to pause.
    Enum.each(state.regimens, fn({pid, regimen, items, start_time, flag}) ->
      GenServer.cast(pid, :pause)
    end)

    {:noreply, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  # This strips out pids, tuples and whatnot for json status updates
  def handle_call(:jsonable, _from, state) do
    regimen_info_list = Enum.map(state.regimens, fn({_pid, regimen, time, items, flag}) ->
      %{regimen: regimen,
        info: %{
          start_time: time,
          status: flag}}
    end)
    {_pid, cs} = state.current_sequence || {nil, nil}
    jsonable =
      %{process_info: regimen_info_list,
        current_sequence: cs,
        sequence_log: state.sequence_log}
    {:reply, jsonable, state}
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
        now = Timex.now()
        start_time = Timex.shift(now, hours: -now.hour, seconds: -now.second)
        {:ok, pid} = Regimen.VM.start_link(regimen, [], start_time)
        reg_tup = {pid, regimen, [], start_time, :normal}
        {:reply, :starting, %State{state | regimens: current ++ [reg_tup]}}

      # If the regimen is in paused state.
      {_pid, ^regimen, _finished_items, _start_time, :paused} ->
        #TODO: Restart paused regimens.
        Logger.warn("Starting paused regimens is not working yet.")
        {:reply, :todo, state}

      # If the regimen is already running.
      {_pid, ^regimen, _finished_items, _start_time, :normal} ->
        Logger.warn("Regimen is already started!")
        {:reply, :already_started, state}
    end
  end

  # The Sequence finished. Cleanup if its still alive..
  def handle_info({:done, {:sequence, pid, _sequence}}, state) do
    GenServer.stop(pid, :normal)
    {:noreply, %State{state | current_sequence: nil}}
  end

  # A regimen is ready to be stopped.
  def handle_info({:done, {:regimen, pid, regimen}}, state) do
    Logger.debug("Regimen: #{regimen.name} has finished.")
    GenServer.stop(pid, :normal)
    reg_tup = find_regimen(regimen, state.regimens)
    {:noreply, %State{state | regimens: state.regimens -- [reg_tup]}}
  end

  # a regimen has changed state, and the scheduler needs to know about it.
  def handle_info({:update, {:regimen,
      {pid, regimen, finished_items, start_time, flag}}}, state)
  do
    # find the index of this regimen in the list.
    found = Enum.find_index(state.regimens, fn({_,cregimen, _,_,_}) ->
      regimen == cregimen
    end)
    cond do
      is_integer(found) ->
        {:noreply, %State{state | regimens: List.update_at(state.regimens, found,
        fn({^pid, ^regimen, _old_items, ^start_time, _flag}) ->
          {pid, regimen, finished_items, start_time, flag}
        end)}}
      is_nil(found) ->
        # Something is not good. try to clean up.
        Logger.error("Something bad happened updating
                      finished regimen items on #{regimen.name}")
        {:noreply, state}
    end
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
    {:ok, pid} = Sequence.Manager.start_link(sequence)
    tick
    {:noreply, %State{sequence_log: log -- [sequence],
                      current_sequence: {pid, sequence},
                      regimens: regimens}}
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
    Logger.debug("Adding sequence: #{sequence.name}")
    GenServer.call(__MODULE__, {:add, {:sequence, sequence}})
  end

  @doc """
    Add/start a new regimen.
  """
  @spec add_regimen(Regimen.t) :: :ok
  def add_regimen(regimen) do
    Logger.debug("Adding Regimen: #{regimen.name}")
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
  @spec e_stop :: :ok
  def e_stop do
    GenServer.cast(__MODULE__, :e_stop)
  end

  def terminate(:normal, _state) do
    Logger.debug("Farmbot Scheduler died. This is not good.")
  end

  def terminate(reason, state) do
    Logger.error("Farmbot Scheduler died. This is not good.")
    spawn fn -> RPC.MessageHandler.send_status end
    Logger.debug("REASON: #{inspect reason}")
    Logger.debug("STATE: #{inspect state}")
  end
end
