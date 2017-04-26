defmodule Farmware.Tracker do
  @moduledoc """
    There is only one farmbot, so we can only execute one script at a time
    This module should queue them up maybe?
    similar to Rails worker system but no scaling?
  """

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
      queue: [FarmScript.t], # list of farm scripts that should be ran?
      worker: pid
    }
    defstruct [queue: [], worker: nil]
  end

  use GenStage
  require Logger
  alias Farmware.Worker
  alias Farmware.FarmScript

  @spec init(any) :: {:producer, State.t}
  def init(_) do
    Logger.info "Starting Farmware Tracker"
    unless File.exists?("/tmp/images"), do: File.mkdir_p("/tmp/images")

    # trap the exit of worker process
    Process.flag(:trap_exit, true)
    {:ok, pid} = Worker.start_link()
    {:producer, %State{worker: pid} }
  end

  @doc """
    Starts the FarmScript tracker
  """
  @spec start_link :: {:ok, pid}
  def start_link, do: GenStage.start_link(__MODULE__, [], name: __MODULE__)

  @doc """
    Add a script to the queue
    can we remove a script from the queue?
  """
  @spec add(FarmScript.t) :: no_return
  def add(%FarmScript{} = scr), do: GenServer.cast(__MODULE__, {:add, scr})

  @doc """
    Gets the state of the tracker.
  """
  @spec get_state :: State.t
  def get_state, do: GenServer.call(__MODULE__, :get_state)

  # GenStage stuffs

  # handle_demand gets called when the Worker is done with whatever else it
  # was doing.
  def handle_demand(demand, state) when demand > 0 do
    # reverse the events so they get executed in order.
    events = Enum.reverse(state.queue)
    # dispatch said events, and make sure to clear the queue.
    {:noreply, events, %State{state | queue: []}}
  end

  # NOTE(connor): the queue will be backwards here
  # account for that later, or just put it on the end of the list?
  def handle_cast({:add, scr}, state) do
    if state.queue == [],
      do: {:noreply, [scr], %State{state | queue: []}},
      else: {:noreply, [], %State{state | queue: [scr | state.queue]}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, [], state}
  end

  # handle exit of worker process
  def handle_info({:EXIT, pid, reason}, state) do
    if pid == state.worker do
      Logger.error "Farmware Worker died: #{inspect reason}"
      {:ok, pid} = Worker.start_link
      {:noreply, [], %State{state | worker: pid }}
    else
      Logger.info "Farmware tracker intercepted a process exit...?"
      {:noreply, [], state}
    end
  end
end
