defmodule SequenceManager do
  use GenServer
  require Logger

  def init(_arge) do
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

  def handle_call({:add, seq}, _from, %{current: nil, global_vars: globals, log: []})
  when is_map(seq) do
    {:ok, pid} = SequencerVM.start_link(seq)
    {:reply, "starting sequence", %{current: pid, global_vars: globals, log: []}}
  end

  # Add a new sequence to the log
  def handle_call({:add, seq}, _from, %{current: current, global_vars: globals, log: log}) do
    RPCMessageHandler.log("Adding sequence to queue.")
    {:reply, "queueing sequence", %{current: current, global_vars: globals, log: [seq | log]}}
  end

  def handle_call(:pause, _from, %{current: current, global_vars: globals, log: more})  when is_pid(current) do
    cond do
      Process.alive?(current) -> GenServer.call(current, :pause)
    end
    {:reply, :ok, %{current: current, global_vars: globals, log: more}}
  end

  def handle_call(:resume, _from, %{current: current, global_vars: globals, log: more}) when is_pid(current) do
    cond do
      Process.alive?(current) -> GenServer.cast(current, :resume)
    end
    {:reply, :ok, %{current: current, global_vars: globals, log: more}}
  end

  # done when there are no more sequences to run.
  def handle_info({:done, pid}, %{current: _, global_vars: globals, log: []}) do
    RPCMessageHandler.log("No more Sequences to run.")
    GenServer.stop(pid, :normal)
    {:noreply, %{current: nil, global_vars: globals, log: []}}
  end

  # There is in fact more sequences to run
  def handle_info({:done, pid}, %{current: _current, global_vars: globals, log: more}) do
    RPCMessageHandler.log("Running next sequence")
    GenServer.stop(pid, :normal)
    seq = List.last(more)
    {:ok, new_pid} = SequencerVM.start_link(seq)
    {:noreply,  %{current: new_pid, global_vars: globals, log: more -- [seq]}}
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
