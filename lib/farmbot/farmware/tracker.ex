defmodule Farmware.Tracker do
  @moduledoc """
    There is only one farmbot, so we can only execute one script at a time
    This module should queue them up maybe?
    similar to Rails worker system but no scaling?
  """

  use GenStage
  require Logger
  alias Farmware.{FarmScript, Worker}
  alias Farmbot.Context

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
      queue: [FarmScript.t], # list of farm scripts that should be ran?
      worker: pid,
      context: Context.t
    }
    defstruct [queue: [], worker: nil, context: nil]
  end

  def init(context) do
    Logger.info "Starting Farmware Tracker"
    unless File.exists?("/tmp/images"), do: File.mkdir_p("/tmp/images")

    # trap the exit of worker process
    Process.flag(:trap_exit, true)
    {:ok, pid} = Worker.start_link(context, name: Worker)
    {:producer, %State{worker: pid, context: context} }
  end

  @doc """
    Starts the FarmScript tracker
  """
  def start_link(%Context{} = ctx, opts),
    do: GenStage.start_link(__MODULE__, ctx, opts)

  @doc """
    Add a script to the queue
    can we remove a script from the queue?
  """
  @spec add(Context.t, FarmScript.t) :: no_return
  def add(%Context{} = ctx, %FarmScript{} = scr), do: GenServer.cast(ctx.farmware_tracker, {:add, scr})

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

  # handle exit of worker process
  def handle_info({:EXIT, pid, reason}, state) do
    if pid == state.worker do
      Logger.error "Farmware Worker died: #{inspect reason}"
      {:ok, pid} = Worker.start_link(state.context, name: Worker)
      {:noreply, [], %State{state | worker: pid }}
    else
      Logger.info "Farmware tracker intercepted a process exit...?"
      {:noreply, [], state}
    end
  end
end
