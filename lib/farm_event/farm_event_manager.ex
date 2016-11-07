defmodule FarmEventManager do
  @save_interval 10000
  @tick_interval 1500
  @log_tag "FarmEventManager"
  require Logger
  @moduledoc """
    This isn't an event manager contrary to module name.
    Long story short we called these tasks "events".
    So it should be phrased as "FarmEvent Manager"
    This module is the tracker that allows regimen_items to gracefully start sequences.
  """

  defmodule State do
    @moduledoc false

    @type regimen_list :: list({pid,Regimen.t, [RegimenItem.t], DateTime.t})

    @type t :: %__MODULE__{
      paused_regimens: regimen_list,
      running_regimens: regimen_list,
      current_sequence: list({pid, Sequence.t}) | nil,
      paused_sequences: list({pid, Sequence.t}),
      sequence_log: list(Sequence.t)
    }

    defstruct [
      paused_regimens: [],    # [{pid, regimen, finished_items, time}]
      running_regimens: [],   # [{pid, regimen, finished_items, time}]
      current_sequence: nil,  # {pid, sequence} | nil
      paused_sequences: [] ,  # [{pid, sequence}]
      sequence_log: []        # [sequence]
    ]

    def init(%{
      paused_regimens: pr,
      running_regimens: rr,
      current_sequence: cs,
      sequence_log: sl
      })
    do
      %__MODULE__{
        paused_regimens: pr,
        running_regimens: rr,
        current_sequence: cs,
        sequence_log: sl
      }
    end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    tick
    {:ok, load}
  end

  def tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  @spec load :: FarmEventManager.State.t
  def load do
    default_state = %State{}
    with {:ok, last_state} <- SafeStorage.read(__MODULE__) do
      spawn fn -> restart(State.init(last_state)) end
    end
    default_state
  end

  @doc """
    I DONT LIKE THIS
  """
  @spec restart(State.t) :: :ok
  def restart(%State{} = last_state) do
    # needs_to_be_restarted = last_state.running_regimens
    # Enum.each(needs_to_be_restarted, fn({_, regimen, items, time}) ->
    #   restart_regimen(regimen, items, time)
    # end)
  end

  def restart(state) do
    Logger.warn("FarmEventManager wont restart last state: #{inspect state}")
    :ok
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add, {:sequence, sequence}}, _from, state) do
    {:reply, :ok,
      Map.put(state, :sequence_log, state.sequence_log ++ [sequence])}
  end

  # add a new regimen
  def handle_call({:add, {:regimen, regimen}}, _from, state) do
    now = Timex.now()
    start_time = Timex.shift(now, hours: -now.hour, seconds: -now.second)
    {:ok, pid} = RegimenVM.start_link(regimen, [], start_time)
    {:reply, :ok,
      Map.put(state, :running_regimens, state.running_regimens ++ [{pid, regimen, [], start_time}])}
  end

  # restart a regiment
  def handle_call({:add, {:regimen, regimen, items, time}}, _from, state) do
    start_time = time
    {:ok, pid} = RegimenVM.start_link(regimen, items, start_time)
    {:reply, :ok,
      Map.put(state, :running_regimens, state.running_regimens ++ [{pid, regimen, items, start_time}])}
  end

  # This strips out pids and whatnot for json status updates
  def handle_call(:jsonable, _from, state) do
  # I CAN DO BETTER
  pr = Enum.map(state.paused_regimens, fn ({_, regimen, _, _}) -> regimen end)
  rr = Enum.map(state.running_regimens, fn ({_, regimen, _, _}) -> regimen end)
  ps = Enum.map(state.paused_sequences, fn ({_, seq}) -> seq end)
  {_pid, cs} = state.current_sequence || {nil, nil}
  sl = state.paused_sequences
  jsonable = %{paused_regimens: pr,
    running_regimens: rr,
    current_sequence: cs,
    paused_sequences: ps,
    sequence_log: sl}
  {:reply, jsonable, state}
end

  # The Sequence finished. Cleanup.
  def handle_info({:done, {:sequence, pid, _sequence}}, %{
    paused_regimens: pr,
    running_regimens: rr,
    current_sequence: _cs,
    paused_sequences: ps,
    sequence_log: sl
    })
  do
    GenServer.stop(pid, :normal)
    {:noreply, %{
      paused_regimens: pr,
      running_regimens: rr,
      current_sequence: nil,
      paused_sequences: ps,
      sequence_log: sl
      }}
  end

  # A regimen is ready to be stopped.
  # It could be in the list of paused_regimens, or the list of
  # running_regimens so we stop it first, then find it, then
  # remove it from its respective list.
  def handle_info({:done, {:regimen, pid, regimen}}, state) do
    GenServer.stop(pid, :normal)
    # find the index in running regimens
    running_index = Enum.find_index(state.running_regimens, fn({reg_pid, reg_regimen, _, _}) ->
      ((regimen == reg_regimen) and (pid == reg_pid))
    end)

    # if the result is an integer, delete that index.
    r = cond do
      is_integer(running_index) -> List.delete_at(state.running_regimens, running_index)
      true -> state.running_regimens
    end

    # find the index in paused regimens
    paused_index = Enum.find_index(state.paused_regimens, fn({reg_pid, reg_regimen, _, _}) ->
      ((regimen == reg_regimen) and (pid == reg_pid))
    end)

    # if the result is an integer, delete that index.
    p = cond do
      is_integer(paused_index) -> List.delete_at(state.running_regimens, paused_index)
      true -> state.paused_regimens
    end

    {:noreply, %{
      paused_regimens: p,
      running_regimens: r,
      paused_sequences: state.paused_sequences,
      current_sequence: state.current_sequence,
      sequence_log: state.sequence_log
    }}
  end

  # a regimen has completed items
  def handle_info({:done, {:regimen_items, {pid, regimen, finished_items, start_time}}}, state) do
    index = Enum.find_index(state.running_regimens, fn({reg_pid, reg_regimen, _, _}) ->
      ((regimen == reg_regimen) and (pid == reg_pid))
    end)
    rr = List.replace_at(state.running_regimens, index, {pid, regimen, finished_items, start_time} )
    {:noreply, %{
      paused_regimens: state.paused_regimens,
      running_regimens: rr,
      paused_sequences: state.paused_sequences,
      current_sequence: state.current_sequence,
      sequence_log: state.sequence_log
    }}
  end

  # start a sequence when there isnt currently one running.
  def handle_info(:tick, %{
    paused_regimens: pr,
    running_regimens: rr,
    current_sequence: nil,
    paused_sequences: ps,
    sequence_log: sl
    })
  do
    if Enum.empty?(sl) do
      next = %{
        paused_regimens: pr,
        paused_sequences: ps,
        running_regimens: rr,
        current_sequence: nil,
        sequence_log: sl }
      SafeStorage.write(__MODULE__, :erlang.term_to_binary(next))
      tick
      {:noreply, next}
    else
      s = List.first(sl)
      {:ok, pid} = SequenceManager.start_link(s)
      next = %{
        paused_regimens: pr,
        paused_sequences: ps,
        running_regimens: rr,
        current_sequence: {pid, s},
        sequence_log: sl -- [s] }
      SafeStorage.write(__MODULE__, :erlang.term_to_binary(next))
      tick
      {:noreply, next}
    end
  end

  # if a sequence is running, wait for it to finish.
  def handle_info(:tick, state) do
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
    tick
    {:noreply, state}
  end

  @spec add_sequence(Sequence.t) :: :ok
  def add_sequence(sequence) do
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
    Restarts a regimen.
  """
  @spec restart_regimen(Regimen.t, list(RegimenItem.t), DateTime.t) :: :ok
  def restart_regimen(regimen, ommitted_items, time) do
    Logger.debug("Adding Regimen: #{regimen.name}")
    GenServer.call(__MODULE__, {:add, {:regimen, regimen, ommitted_items, time}})
  end

  @doc """
    Gets the current state of FarmEventManager.
  """
  @spec state() :: FarmEventManager.State.t
  def state do
    GenServer.call(__MODULE__, :state)
  end

  def terminate(:normal, _state) do
    Logger.debug("Farm Event Manager died. This is not good.")
  end

  def terminate(reason, state) do
    Logger.error("Farm Event Manager died. This is not good.")
    spawn fn -> RPC.MessageHandler.send_status end
    IO.inspect reason
    IO.inspect state
  end
end
