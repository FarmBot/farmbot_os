defmodule SequenceManager do
  use GenServer
  require Logger
  def init(_arge) do
    {:ok, %{current: nil, global_vars: %{}, log: []}}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_call({:add, seq}, _from, %{current: nil, global_vars: globals, log: []}) do
    pid = Sequencer.do_sequence(seq)
    {:reply, "starting sequence", %{current: pid, global_vars: globals, log: []}}
  end

  # Add a new sequence to the log
  def handle_call({:add, seq}, _from, %{current: current, global_vars: globals, log: log}) do
    new_log = [seq | log]
    RPCMessageHandler.log("Adding sequence to queue.")
    {:reply, "queueing sequence", %{current: current, global_vars: globals, log: new_log}}
  end

  # done when there are no more sequences to run.
  def handle_call({:done, _pid}, _from, %{current: _current, global_vars: globals, log: []}) do
    RPCMessageHandler.log("No more Sequences to run.")
    {:reply, :ok,  %{current: nil, global_vars: globals, log: []}}
  end

  # There is in fact more sequences to run
  def handle_call({:done, _pid}, _from, %{current: _current, global_vars: globals, log: more}) do
    RPCMessageHandler.log("Running next sequence")
    seq = List.last(more)
    new_pid = Sequencer.do_sequence(seq)
    {:reply, :ok,  %{current: new_pid, global_vars: globals, log: more -- [seq]}}
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

  def do_sequence(seq) when is_map(seq) do
    huh = GenServer.call(__MODULE__, {:add, seq})
    RPCMessageHandler.log(huh)
  end
end
