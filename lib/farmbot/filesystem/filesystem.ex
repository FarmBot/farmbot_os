defmodule Farmbot.FileSystem do
  @moduledoc """
    Handles filesystem reads and writes and formatting.
  """

  require Logger
  use GenServer
  def start_link(env) do
    GenServer.start_link(__MODULE__, env, name: __MODULE__)
  end

  def init(env) do
    Logger.debug ">> is starting file system services."
    mod = Module.concat([FileSystem, Utils, env])
    mod.fs_init
    {:ok, %{}}
  end

  defp mount_read_only do
    Logger.debug ">>'s filesystem is safe!"
    :ok
  end

  defp mount_read_write do
    Logger.debug ">>'s file system is being backed up! please be careful."
    :ok
  end

  def factory_reset do

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
    :ok = mount_read_write
    f = fun.()
    :ok = mount_read_only
    f
  end
end
