defmodule FarmEventManager do
  @save_interval 10000
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
    Process.send_after(self(), :save, @save_interval)
    {:ok, load}
  end

  def load do
    # TODO load state from disk
    default_state = %{
      paused_regimens: [],   # [{pid, regimen}]
      running_regimens: [],  # [{pid, regimen}]
      current_sequence: nil, # {pid, sequence}
      sequence_log: [],      # [sequence]
      paused_sequences: []   # [{pid, sequence}]
    }
    default_state
  end

  def save(_state) do
    # TODO Save state to disk.
  end

  # add a sequence when one isnt currently running and there is nothing in the list
  def handle_call( {:add, {:sequence, sequence}}, _from, %{
    paused_regimens: pr,
    running_regimens: rr,
    current_sequence: nil,
    sequence_log: [],
    paused_sequences: ps
  }) do
    RPCMessageHandler.log("Starting sequence now", "success_toast")
    {:ok, pid} = SequenceManager.start_link(sequence)
    {:reply, "starting sequence", %{
        paused_regimens: pr,
        running_regimens: rr,
        current_sequence: pid,
        sequence_log: [],
        paused_sequences: ps
      }}
  end

  # add a sequence when there is one already running
  def handle_call( {:add, {:sequence, sequence}}, _from, %{
    paused_regimens: pr,
    running_regimens: rr,
    current_sequence: cur,
    sequence_log: log,
    paused_sequences: ps
  }) do
    RPCMessageHandler.log("Adding sequence to queue.", "warning_toast")
    {:reply, "queuing sequence", %{
        paused_regimens: pr,
        running_regimens: rr,
        current_sequence: cur,
        sequence_log: log ++ [sequence],
        paused_sequences: ps
      }}
  end

  def handle_call( {:add, {:regimen, regimen}}, _from, state)
  when is_map(regimen) do
    # Combine both lists of regimens.
    all = state.paused_regimens ++ state.running_regimens

    # check to see if this regimen exists in either list
    check =
    Enum.find(all, nil, fn({_pid, stored_regimen}) ->
      regimen == stored_regimen
    end)

    case check do
      nil -> # this regimen isnt tracked and running yet.
        {:ok, pid} = RegimenVM.start_link(regimen)
        {:reply, :ok,
          Map.put(state,
            :running_regimens, state.running_regimens ++ [{pid, regimen}])}
      _ -> RPCMessageHandler.log(Map.get(regimen, "name") <> " is already started!")
        {:reply, :ok, state}
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:done, {:regimen, {pid, regimen} }}, state) do
    Logger.debug("#{Map.get(regimen, "name")} is complete.")
    Enum.find(state.running_regimens, nil, fn({rpid, rregimen}) ->
      if {rpid, rregimen} == {pid, regimen} do
        {:noreply,
          Map.put(state, :running_regimens,
            state.running_regimens -- [{pid, regimen}])}
      end
    end) ||
    Enum.find(state.paused_regimens, nil, fn({rpid, rregimen}) ->
      if {rpid, rregimen} == {pid, regimen} do
        {:noreply,
          Map.put(state, :paused_regimens,
            state.paused_regimens -- [{pid, regimen}])}
      end
    end)
  end

  def handle_info({:done, {:sequence, pid}}, %{
      paused_regimens: pr,
      running_regimens: rr,
      current_sequence: _cur,
      sequence_log: [],
      paused_sequences: ps
    }) do
    GenServer.stop(pid, :normal)
    RPCMessageHandler.log("Sequence Finished without errors!", ["success_toast", "ticker"])
    Logger.debug("FarmEventManager is out of sequences to run.")
    {:noreply,
      %{
        paused_regimens: pr,
        running_regimens: rr,
        current_sequence: nil,
        sequence_log: [],
        paused_sequences: ps
        }}
  end

  def handle_info({:done, {:sequence, pid}},
        %{
            paused_regimens: pr,
            running_regimens: rr,
            current_sequence: _old_pid,
            sequence_log: log,
            paused_sequences: ps
          })
  do
    GenServer.stop(pid, :normal)
    RPCMessageHandler.log("Sequence Finished without errors!", ["success_toast", "ticker"])
    Logger.debug("FarmEventManager running next sequence.")
    next_seq = List.first(log)
    {:ok, new_pid} = SequenceManager.start_link(next_seq)
    {:noreply,
      %{
          paused_regimens: pr,
          running_regimens: rr,
          current_sequence: new_pid,
          sequence_log: log -- [next_seq],
          paused_sequences: ps
        }}
  end

  def handle_info(:save, state) do
    save(state)
    Process.send_after(self(), :save, @save_interval)
    {:noreply, state}
  end

  def terminate(reason, state) do
    Logger.debug("Farm Event Manager died. This is not good.")
    IO.inspect reason
    IO.inspect state
    save(state)
  end
end
