defmodule SequenceManager do
  use GenServer
  require Logger
  def init(_arge) do
    {:ok, %{sequence_running: false, global_vars: %{}, sequences: [] }}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def running_sequence do
    GenServer.call(__MODULE__, :get_running_sequence)
  end

  def sequence_start(pid) do
    GenServer.call(__MODULE__, {:sequence_start, pid})
  end

  def sequence_finish(pid) do
    GenServer.call(__MODULE__, {:sequence_finish, pid})
  end

  def add_sequence(sequence) do
    GenServer.call(__MODULE__, {:add_sequence, sequence})
  end

  def handle_call(:get_running_sequence, _from, %{sequence_running: seq, global_vars: global, sequences: s }) do
    {:reply, seq, %{sequence_running: seq, global_vars: global, sequences: s } }
  end

  def handle_call({:sequence_start, pid}, _from, %{sequence_running: false, global_vars: global, sequences: s }) do
    {:reply, :ok, %{sequence_running: pid, global_vars: global, sequences: s } }
  end

  def handle_call({:sequence_finish, _pid}, _from, %{sequence_running: _, global_vars: global, sequences: s }) do
    spawn fn -> Process.sleep(5000); Sequencer.do_sequence(List.last(s)) end
    {:reply, :ok, %{sequence_running: false, global_vars: global, sequences: [s] -- [List.last(s)] } }
  end

  def handle_call({:add_sequence, sequence}, _from, %{sequence_running: _, global_vars: global, sequences: s }) do
    {:reply, :ok, %{sequence_running: false, global_vars: global, sequences: [sequence | s] } }
  end
end
