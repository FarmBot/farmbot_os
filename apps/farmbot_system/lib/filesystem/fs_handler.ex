defmodule Farmbot.System.FS do
  @moduledoc """
    Handles filesystem reads and writes and formatting.
  """

  require Logger
  use GenStage
  @path Application.get_env(:farmbot_system, :path)

  def start_link(target),
    do: GenStage.start_link(__MODULE__, target, name: __MODULE__)

  def init(target) do
    Logger.debug ">> #{target} FileSystem Init"
    mod = Module.concat([Farmbot, System, target, FileSystem])
    mod.fs_init
    mod.mount_read_only
    {:producer, []}
  end

  @doc """
    Safely executes FileSystem commands.\n
    * mounts the file system as read_write
    * executes function
    * mounts the file system as read_only again.
    Example:
      Iex> transaction fn() -> File.write("/state/bs.txt" , "hey") end
  """
  def transaction(fun) when is_function(fun) do
    GenServer.cast(__MODULE__, {:add_transaction, fun})
  end

  @spec get_state :: [any]
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def handle_call(:get_state, _, state), do: {:reply, [], state, state}

  # where there is no other queued up stuff
  def handle_cast({:add_transaction, fun}, []) do
    {:noreply, [fun], []}
  end

  def handle_cast({:add_transaction, fun}, queue) do
    Logger.debug ">> is queueing a fs transaction"
    {:noreply, [], [fun | queue]}
  end

  def handle_demand(demand, queue) when demand > 0 do
    trans = Enum.reverse(queue)
    {:noreply, trans, []}
  end

  @doc """
    Returns the path where farmbot keeps its persistant data.
  """
  def path, do: @path

  # BEHAVIOR
  @type return_type :: :ok | {:error, term}
  @callback mount_read_only() :: return_type
  @callback mount_read_write() :: return_type
  @callback fs_init() :: return_type
end
