defmodule SequenceManager do
  use GenServer
  require Logger

  def init(_arge) do
    Process.flag(:trap_exit, true)
    {:ok, %{current: nil, global_vars: %{}, log: []}}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_call(:e_stop, _from, %{current: pid, global_vars: _, log: _})
  when is_pid(pid) do
    pid_exit = Process.exit(pid, :e_stop)
    {:reply, pid_exit, %{current: nil, global_vars: %{}, log: []}}
  end

  def handle_call(:e_stop, _from, %{current: nil, global_vars: _, log: _}) do
    {:reply, :no_process, %{current: nil, global_vars: %{}, log: []}}
  end

  # no sequences running, no sequences in list.
  def handle_call({:add, seq}, _from, %{current: nil, global_vars: globals, log: []})
  when is_map(seq) do
    {:ok, pid} = SequencerVM.start_link(seq)
    {:reply, "starting sequence", %{current: pid, global_vars: globals, log: []}}
  end

  # Add a new sequence to the log when there are no other sequences running.
  def handle_call({:add, seq}, _from, %{current: nil, global_vars: globals, log: log})
  when is_map(seq) do
    RPCMessageHandler.log("Other sequences paused. Starting new one. ")
    {:ok, pid} = SequencerVM.start_link(seq)
    {:reply, "queueing sequence", %{current: pid, global_vars: globals, log: log}}
  end

  # Add a new sequence to the log
  def handle_call({:add, seq}, _from, %{current: current, global_vars: globals, log: log})
  when is_map(seq) and is_pid(current) do
    RPCMessageHandler.log("Adding sequence to queue.")
    {:reply, "queueing sequence", %{current: current, global_vars: globals, log: [log | seq]}}
  end

  def handle_call({:pause, pid}, _from, %{current: current, global_vars: globals, log: more}) do
    cond do
      Process.alive?(pid) ->
        GenServer.call(current, :pause)
        {:reply, :ok, %{current: nil, global_vars: globals, log: [ pid | more ]}}
    end
  end

  def handle_call({:resume, pid}, _from, %{current: _current, global_vars: globals, log: more}) do
    cond do
      Process.alive?(pid) ->
        GenServer.cast(pid, :resume)
        {:reply, :ok, %{current: pid, global_vars: globals, log: more}}
    end
  end

  def handle_info({:done, pid}, %{current: _current, global_vars: globals, log: []}) do
    GenServer.stop(pid, :normal)
    RPCMessageHandler.log("No more sequences.")
    {:noreply, %{current: nil, global_vars: globals, log: [] } }
  end

  def handle_info({:done, pid}, %{current: _current, global_vars: globals, log: log}) do
    GenServer.stop(pid, :normal)
    RPCMessageHandler.log("Running next sequence")
    next = List.first(log)
    cond do
      is_nil(next) -> {:noreply, %{current: nil, global_vars: globals, log: []}}
      is_map(next) ->
          {:ok, next_seq} = SequencerVM.start_link(next)
          {:noreply, %{current: next_seq, global_vars: globals, log: log -- [next]}}
      is_pid(next) ->
        GenServer.cast(next, :resume)
        {:noreply, %{current: next, global_vars: globals, log: log -- [next]}}
    end
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:EXIT, pid, reason}, state) do
    msg = "#{inspect pid} died of unnatural causes: #{inspect reason}"
    Logger.debug(msg)
    RPCMessageHandler.log(msg)
    if state.current == pid do
      handle_info({:done, pid}, state)
    else
      Logger.debug("Sequence Hypervisor has been currupted. ")
      :fail
    end
  end

  def do_sequence(seq) when is_map(seq) do
    huh = GenServer.call(__MODULE__, {:add, seq})
    RPCMessageHandler.log(huh)
    Logger.debug(huh)
  end

  def e_stop do
    GenServer.call(__MODULE__, :e_stop)
  end
end
