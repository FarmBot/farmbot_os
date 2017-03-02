defmodule Sequence.Supervisor do
  @moduledoc """
    Supervisor for Sequences
  """
  @behaviour Farmbot.EventSupervisor
  use GenServer
  use Farmbot.Sync.Database
  require Logger

  @type state :: %{
    # Queue of sequences to run
    q: :queue.queue,
    # list of pids waiting for the current sequence to finish
    blocks: [pid],
    # the running sequence
    running: {pid, Sequence.t} | nil
  }

  @doc """
    Starts the Sequence Supervisor.
  """
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  # @spec init([]) :: {:ok, state}
  def init([]) do
    Process.flag(:trap_exit, true)
    {:ok, %{q: :queue.new(), blocks: [], running: nil}}
  end

  @doc """
    Add a child to this supervisor
  """
  def add_child(%Sequence{} = sequence, _time) do
    GenServer.call(__MODULE__, {:add, sequence})
  end

  def add_child(_,_), do: {:error, :not_sequence}

  @doc """
    Remove a child
  """
  def remove_child(%Sequence{} = sequence) do
    GenServer.call(__MODULE__, {:stop, sequence})
  end

  def remove_child(_), do: {:error, :not_sequence}

  @doc """
    Gets the state
  """
  @spec get_state :: state
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @spec handle_call({:add, Sequence.t}, reference, state)
    :: {:reply, {:ok, pid}, state}
  def handle_call({:add, sequence}, _from, state) do
    # check if we are running or not
    case state.running do
      {_pid, _sequence} ->
        # queue up a sequence
        Logger.debug ">> is queing up a sequence"
        q = :queue.in(sequence, state.q)
        {:reply, {:ok, :queued}, %{state | q: q}}
      _ ->
        # start it now
        Logger.debug ">> is starting a sequence"
        {:ok, pid} = SequenceRunner.start_link(sequence)
        {:reply, {:ok, pid}, %{state | running: {pid, sequence}}}
    end
  end

  @spec handle_call({:stop, Sequence.t}, reference, state)
    :: {:reply, :ok | {:error, atom}, state}
  def handle_call({:stop, sequence}, _from, state) do
    # check if the sequence is running
    case state.running do
      {pid, rsequence} ->
        # if its currently running, stop it
        if sequence.id == rsequence.id do
          GenServer.stop(pid, :normal)
          # This is actually wrong. We need to start the next sequence
          # in the queue here
          {:reply, :ok, %{state | running: nil}}
        else
          {:reply, :ok, state}
        end
      _ ->
        # if not, pop it from the queue
        q = :queue.filter(fn(qsequence) ->
          qsequence.id != sequence.id
        end, state.q)
        {:reply, :ok, %{state | q: q}}
    end
  end

  @spec handle_call(:get_state, reference, state) :: {:reply, state, state}
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  # When a sequence is complete
  @spec handle_info({:EXIT, pid, any}, state) :: {:noreply, state}
  def handle_info({:EXIT, pid, reason}, state) do
    unless reason == :normal do
      Logger.warn ">> sequence exited unnaturally: #{inspect reason}"
    end
    case :queue.out(state.q) do
      {:empty, q} ->
        Logger.info ">> no more sequences to run right now."
        {:noreply, %{state | q: q, running: nil}}
      {{:value, sequence}, q} ->
        Logger.debug ">> is starting a sequence"
        {:ok, pid} = SequenceRunner.start_link(sequence)
        {:noreply, %{state | q: q, running: {pid, sequence}}}
    end
  end
end
