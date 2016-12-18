defmodule Farmbot.FileSystem do
  @moduledoc """
    Handles filesystem reads and writes and formatting.
  """

  require Logger
  use GenServer

  def start_link({env, target}),
    do: GenServer.start_link(__MODULE__, {env, target}, name: __MODULE__)

  def init({env, target}) do
    Logger.debug ">> is starting file system services."
    mod = Module.concat([FileSystem, Utils, env, target])
    mod.fs_init
    mod.mount_read_only
    {:ok, {mod, :read_only, []}}
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
    GenServer.cast(__MODULE__, {:transaction, fun, self()})
    receive do
      {^fun, ret} -> ret
      e -> raise "Bad return value for transaction: #{inspect e}"
    end
  end

  @doc """
    Resets all the data about this Farmbot
  """
  def factory_reset do
    Logger.debug ">> is going to be completely reset! Goodbye!"
    GenServer.cast(__MODULE__, :factory_reset)
  end

  # if we are in read only mode, start the stuff right now.
  def handle_cast({:transaction, fun, pid}, {module, :read_only, _}) do
    do_stuff(module, fun, pid)
    {:noreply, {module, :read_write, []}}
  end

  # if we are in read_write mode, add this transaction to the queue.
  def handle_cast({:transaction, fun, pid}, {module, :read_write, l}) do
    {:noreply, {module, :read_write, l ++ [{fun, pid}]}}
  end

  # handle the factory reset cast.
  # We don't care about what is happening right now
  def handle_cast(:factory_reset, {module, _, _}) do
    module.factory_reset
    :crash_if_we_get_this_far
  end

  # sent from the do_stuff function
  # When it finishes and there is nothing else in the queue.
  def handle_info(:transaction_finish, {module, _, []}) do
    {:noreply, {module, :read_only, []}}
  end

  # when a transaction finishes with more items in the queue
  def handle_info(:transaction_finish, {module, _, l}) do
    {fun, pid} = List.first(l)
    do_stuff(module, fun, pid)
    {:noreply, {module, :read_write, l -- [{fun, pid}]}}
  end

  defp do_stuff(mod, fun, pid) do
    spawn fn ->
      :ok = mod.mount_read_write
      ret = fun.()
      :ok = mod.mount_read_only
      send(pid, {fun, ret})
      send(__MODULE__, :transaction_finish)
    end
  end
end
