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
    default_state = %{
      paused_regimens: [],    # [{pid, regimen, finished_items, time}]
      running_regimens: [],   # [{pid, regimen, finished_items, time}]
      current_sequence: nil,  # {pid, sequence} | nil
      paused_sequences: [] ,  # [{pid, sequence}]
      sequence_log: []        # [sequence]
    }
    default_state
  end

  def save(state) do
    SafeStorage.write(__MODULE__, :erlang.term_to_binary(state))
  end

  def restart_regimens(old_state) do
    b = Auth.fetch_token
    cond do
      is_map(b) ->
        BotSync.sync()
        Process.sleep(5000)
      true -> restart_regimens(old_state)
    end
    BotSync.sync()
    r = old_state.running_regimens
    |> Enum.map(fn({_old_pid, regimen, finished_items, time}) ->
      Logger.debug("Restarting Regimen")
      {:ok, pid} = RegimenVM.start_link(regimen, finished_items, time)
      {pid, regimen, finished_items, time}
    end)
    GenServer.call(__MODULE__, {:update_running, r})
  end

  # THIS SHOULDNT EXIST I DONT THINK
  def handle_call({:update_running, running}, _from, %{
    paused_regimens: pr,
    running_regimens: _,
    current_sequence: cs,
    sequence_log: sl,
    paused_sequences: ps
  }) do
    {:reply, :ok, %{
      paused_regimens: pr,
      running_regimens: running,
      current_sequence: cs,
      sequence_log: sl,
      paused_sequences: ps
    } }
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
        current_sequence: {pid, sequence},
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
    Enum.find(all, nil, fn({_pid, stored_regimen, _items, _time}) ->
      regimen == stored_regimen
    end)

    case check do
      nil -> # this regimen isnt tracked and running yet.
      # REGIMENS ALWAYS START AT MIDNIGHT TODAY.

      # now = System.monotonic_time(:milliseconds)
      now = :os.system_time
      Logger.warn("THE REGIMEN IS TIMER IS WRONG")
      # We need to know how many hours it has been since midnight. But all we
      # Have is gmt time. 
      start_time = now

      start_time =
        {:ok, pid} = RegimenVM.start_link(regimen, [], start_time)
        {:reply, :ok,
          Map.put(state,
            :running_regimens, state.running_regimens ++ [{pid, regimen, [], start_time}])}
      _ -> RPCMessageHandler.log(Map.get(regimen, "name") <> " is already started!")
        {:reply, :ok, state}
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

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

  def handle_info({:done, {:regimen_items, {pid, regimen, items, time}}}, state) do
    Logger.debug("#{Map.get(regimen, "name")} has completed an item.")
    index = Enum.find_index(state.running_regimens, fn({rpid, rregimen, _ritems, _time}) ->
      {pid, regimen} == {rpid, rregimen}
    end)
    cond do
      is_integer(index) ->
        new_running = List.replace_at(state.running_regimens, index, {pid, regimen, items, time})
        {:noreply, Map.put(state, :running_regimens, new_running)}
      true ->
        Logger.debug("bad index")
        {:noreply, state}
    end
  end

  def handle_info({:done, {:regimen, {pid, regimen} }}, state) do
    Logger.debug("#{Map.get(regimen, "name")} is stopping.")
    Enum.find_value(state.running_regimens, nil, fn({rpid, rregimen, items, time}) ->
      if {rpid, rregimen} == {pid, regimen} do
        {:noreply,
          Map.put(state, :running_regimens,
            state.running_regimens -- [{pid, regimen, items, time}])}
      end
    end) ||
    Enum.find_value(state.paused_regimens, nil, fn({rpid, rregimen,items, time}) ->
      if {rpid, rregimen} == {pid, regimen} do
        {:noreply,
          Map.put(state, :paused_regimens,
            state.paused_regimens -- [{pid, regimen, items, time}])}
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
          current_sequence: {new_pid, next_seq},
          sequence_log: log -- [next_seq],
          paused_sequences: ps
        }}
  end

  def handle_info(:save, state) do
    save(state)
    Process.send_after(self(), :save, @save_interval)
    {:noreply, state}
  end

  def terminate(:normal, state) do
    Logger.debug("Farm Event Manager died. This is not good.")
    save(state)
  end

  def terminate(reason, state) do
    Logger.debug("Farm Event Manager died. This is not good.")
    spawn fn -> RPCMessageHandler.send_status end
    IO.inspect reason
    IO.inspect state
  end
end
