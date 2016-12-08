defmodule Farmbot.Scheduler.Sequence.Manager do
  alias Farmbot.Sync.Database.Sequence, as: Sequence
  alias Farmbot.Scheduler.Sequence.VM, as: SequenceVM
  @moduledoc """
    This Module is a state machine that tracks a sequence thru its lifecycle.
  """
  use GenServer
  require Logger


  def init(%Sequence{} = sequence) do
    # Log somethingdebug("Sequence Manager Init.")
    Process.flag(:trap_exit, true)
    {:ok, pid} = SequenceVM.start_link(sequence)
    {:ok, %{current: pid, global_vars: %{}, log: []}}
  end

  def start_link(sequence) do
    GenServer.start_link(__MODULE__, sequence, name: __MODULE__)
  end

  def handle_call(:e_stop, _from, %{current: nil, global_vars: _, log: _}) do
    {:reply, :ok, %{current: nil, global_vars: %{}, log: []}}
  end

  # no sequences running, no sequences in list.
  def handle_call({:add, %Sequence{} = seq}, _from,
    %{current: nil, global_vars: globals, log: []})
  do
    {:ok, pid} = SequenceVM.start_link(seq)
    {:reply,
      "starting sequence",
      %{current: pid, global_vars: globals, log: []}}
  end

  # Add a new sequence to the log when there are no other sequences running.
  def handle_call({:add, %Sequence{} = seq}, _from,
    %{current: nil, global_vars: globals, log: log})
  do
    {:ok, pid} = SequenceVM.start_link(seq)
    {:reply,
     "starting sequence",
     %{current: pid, global_vars: globals, log: log}}
  end

  # Add a new sequence to the log
  def handle_call({:add, %Sequence{} = seq},
    _from,
    %{current: current, global_vars: globals, log: log})
  when is_pid(current) do
    {:reply,
     "queueing sequence",
     %{current: current, global_vars: globals, log: [log | seq]}}
  end

  def handle_call({:pause, pid},
    _from,
    %{current: current, global_vars: globals, log: more})
  when is_pid(pid) do
    if Process.alive?(pid) do
        GenServer.call(current, :pause)
        {:reply, :ok, %{current: nil, global_vars: globals, log: [pid | more]}}
    end
  end

  def handle_call({:resume, pid},
    _from,
    %{current: _current, global_vars: globals, log: more})
  when is_pid(pid)
  do
      if Process.alive?(pid) do
        GenServer.cast(pid, :resume)
        {:reply, :ok, %{current: pid, global_vars: globals, log: more}}
      end
  end

  def handle_info({:done, pid, sequence},
    %{current: _current, global_vars: globals, log: []})
  when is_pid(pid) do
    if Process.alive?(pid) do
      GenServer.stop(pid, :normal)
    end
    # Log something here("No more sub sequences.", [], [__MODULE__])
    send(Farmbot.Scheduler, {:done, {:sequence, self(), sequence}})
    {:noreply, %{current: nil, global_vars: globals, log: []}}
  end

  def handle_info({:done, pid, _sequence},
    %{current: _current, global_vars: globals, log: log})
  when is_pid(pid) do
    if Process.alive?(pid) do
      GenServer.stop(pid, :normal)
    end
    # Log something here("Running next sub sequence", [], [__MODULE__])
    next = List.first(log)
    cond do
      is_nil(next) -> {:noreply, %{current: nil, global_vars: globals, log: []}}
      is_map(next) ->
          {:ok, next_seq} = SequenceVM.start_link(next)
          {:noreply,
           %{current: next_seq, global_vars: globals, log: log -- [next]}}
      is_pid(next) ->
        GenServer.cast(next, :resume)
        {:noreply, %{current: next, global_vars: globals, log: log -- [next]}}
    end
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:EXIT, pid, reason}, state)
  when pid == state do
    Logger.error """
      >> could not complete sequence: #{inspect reason}, #{inspect state}
      """
    handle_info({:done, pid, %{}}, state)
  end

  def terminate(:normal, _state) do
    Logger.debug ">> is shutting down the sequencer."
  end

  def terminate(reason, _state) do
    Logger.error ">> encountered an error in the sequencer: #{inspect reason}"
  end
end
