defmodule Farmbot.System.FS do
  @moduledoc """
    Handles filesystem reads and writes and formatting.
  """

  require Logger
  use GenServer
  @path Application.get_env(:farmbot_system, :path)

  def start_link(target),
    do: GenServer.start_link(__MODULE__, target, name: __MODULE__)

  def init(target) do
    Logger.debug ">> #{target} FileSystem Init"
    mod = Module.concat([Farmbot, System, target, FileSystem])
    mod.fs_init
    mod.mount_read_only
    {:ok, {mod, :read_only, 0}}
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
    # this is kind of dirty
    GenServer.call(__MODULE__, :transaction)
    fun.()
    GenServer.cast(__MODULE__, :transaction_finish)
  end

  # this was the first transaction.
  def handle_call(:transaction, _, {mod, :read_only, 0}) do
    mod.mount_read_write
    {:reply, :ok, {mod, :read_write, 1}}
  end

  # a transaction when there is already at least one other transaction happening.
  def handle_call(:transaction, _, {mod, :read_write, count}) when count > 0 do
    {:reply, :ok, {mod, :read_write, count + 1}}
  end

  # a transaction finished, but it wasnt the last one. so we don't mount read only yet.
  def handle_cast(:transaction_finish, {mod, :read_write, count}) when count > 1 do
    {:noreply, {mod, :read_write, count - 1}}
  end

  # the last transaction finished; remount read only
  def handle_cast(:transaction_finish, {mod, :read_write, 1}) do
    mod.mount_read_only
    {:noreply, {mod, :read_only, 0}}
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
