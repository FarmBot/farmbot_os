defmodule Farmbot.System.FS do
  @moduledoc """
    Handles filesystem reads and writes and formatting.
  """

  require Logger
  use GenStage
  @path Application.get_env(:farmbot, :path)

  def start_link(target),
    do: GenStage.start_link(__MODULE__, target, name: __MODULE__)

  def init(target) do
    Logger.info ">> #{target} FileSystem Init"
    mod = Module.concat([Farmbot, System, target, FileSystem])
    mod.fs_init
    mod.mount_read_only
    spawn __MODULE__, :check_update_file, []
    {:producer, []}
  end

  def check_update_file do
    update_file_path = "#{path()}/.post_update"
    case File.stat(update_file_path) do
      {:ok, _file} ->
        Logger.info "We are in post update mode!"
        Farmbot.System.Updates.post_install()
        transaction fn ->
          File.rm!(update_file_path)
        end
      _ ->
        Logger.info "Not in post update mode!" 
        :ok
    end
  end

  @doc ~s"""
    Safely executes FileSystem commands.\n
    * mounts the file system as read_write
    * executes function
    * mounts the file system as read_only again.
    Example:
      Iex> transaction fn() -> File.write("/state/bs.txt" , "hey") end
  """
  @spec transaction(function) :: :ok | nil
  def transaction(function, block? \\ false, timeout \\ 10_000)
  def transaction(fun, false, _timeout) when is_function(fun) do
    # HACK(Connor) i dont want to handle two different :add_transactions
    GenServer.call(__MODULE__, {:add_transaction, fun, __MODULE__})
  end

  def transaction(fun, true, timeout) when is_function(fun) do
    task = Task.async(fn() ->
      GenServer.call(__MODULE__, {:add_transaction, fun, self()})
      # FIXME(Connor) this is probably.. well terrible
      receive do
        thing -> thing
      end
    end)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, result} ->
        result
      nil ->
        Logger.error "Failed to execute FS transaction  in#{timeout}ms"
        nil
    end
  end

  @spec get_state :: [any]
  def get_state, do: GenServer.call(__MODULE__, :get_state)

  def handle_call(:get_state, _, state), do: {:reply, [], state, state}

  # where there is no other queued up stuff
  def handle_call({:add_transaction, fun, pid}, _from, []) do
    {:reply, :ok, [{fun, pid}], []}
  end

  def handle_call({:add_transaction, fun, pid}, _from, queue) do
    Logger.info ">> is queueing a fs transaction"
    {:reply, :ok, [], [{fun, pid} | queue]}
  end

  def handle_demand(demand, queue) when demand > 0 do
    trans = Enum.reverse(queue)
    {:noreply, trans, []}
  end

  def handle_info(_,state), do: {:noreply, [], state}

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
