defmodule Farmbot.FileSystem do
  @moduledoc """
    Handles filesystem reads and writes and formatting.
  """

  require Logger
  use GenServer
  @path Application.get_env(:farmbot_filesystem, :path)

  def start(_,[%{env: env, target: target}]),
    do: Farmbot.FileSystem.Supervisor.start_link({env, target})

  def start_link({env, target}),
    do: GenServer.start_link(__MODULE__, {env, target}, name: __MODULE__)

  def init({env, target}) do
    Logger.debug ">> FileSystem Init"
    mod = Module.concat([FileSystem, Utils, env, target])
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


  @doc """
    Resets all the data about this Farmbot
  """
  def factory_reset do
    Logger.debug ">> is going to be completely reset! Goodbye!"
    Farmbot.Auth.delete_secret
    Farmbot.FileSystem.ConfigStorage.reset_config
    System.halt(0)
  end
end
