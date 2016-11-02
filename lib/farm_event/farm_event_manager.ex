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

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    # Process.send_after(self(), :save, @save_interval)
    tick
    {:ok, load}
  end

  def tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  def load do
    default_state = %{
      paused_regimens: [],    # [{pid, regimen, finished_items, time}]
      running_regimens: [],   # [{pid, regimen, finished_items, time}]
      current_sequence: nil,  # {pid, sequence} | nil
      paused_sequences: [] ,  # [{pid, sequence}]
      sequence_log: []        # [sequence]
    }
    default_state
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add, {:sequence, sequence}}, _from, state) do
    {:reply, :ok,
      Map.put(state, :sequence_log, state.sequence_log ++ [sequence])}
  end

  def handle_call({:add, {:regimen, regimen}}, _from, state) do
    now = Timex.now()
    start_time = Timex.shift(now, hours: -now.hour, seconds: -now.second)
    {:ok, pid} = RegimenVM.start_link(regimen, start_time)
    {:reply, :ok,
      Map.put(state, :running_regimens, state.running_regimens ++ [{pid, regimen, [], start_time}])}
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
      tick
      {:noreply, %{
        paused_regimens: pr,
        paused_sequences: ps,
        running_regimens: rr,
        current_sequence: nil,
        sequence_log: sl }}
    else
      s = List.first(sl)
      {:ok, pid} = SequenceManager.start_link(s)
      tick
      {:noreply, %{
        paused_regimens: pr,
        paused_sequences: ps,
        running_regimens: rr,
        current_sequence: {pid, s},
        sequence_log: sl -- [s] }}
    end
  end

  # if a sequence is running, wait for it to finish.
  def handle_info(:tick, state) do
    tick
    {:noreply, state}
  end

  def save(state) do
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
  end

  @spec add_sequence(Sequence.t) :: :ok
  def add_sequence(sequence) do
    Logger.debug("Adding sequence: #{sequence.name}")
    GenServer.call(__MODULE__, {:add, {:sequence, sequence}})
  end

  @spec add_regimen(Regimen.t) :: :ok
  def add_regimen(regimen) do
    Logger.debug("Adding Regimen: #{regimen.name}")
    GenServer.call(__MODULE__, {:add, {:regimen, regimen}})
  end

  def state do
    GenServer.call(__MODULE__, :state)
  end

  def terminate(:normal, state) do
    Logger.debug("Farm Event Manager died. This is not good.")
    save(state)
  end

  def terminate(reason, state) do
    Logger.error("Farm Event Manager died. This is not good.")
    spawn fn -> RPCMessageHandler.send_status end
    IO.inspect reason
    IO.inspect state
  end
end
