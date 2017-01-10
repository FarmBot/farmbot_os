defmodule Farmbot.System.Network do
  @moduledoc """
    Network functionality.
  """
  require Logger
  use GenServer

  @spec mod(atom) :: atom
  defp mod(target), do: Module.concat([Farmbot, System, target, Network])

  def init(target) do
    Logger.debug ">> is starting networking"
    m = mod(target)
    {:ok, _cb} = m.start_link
    {:ok, target}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
    Scans for wireless ssids.
  """
  @spec scan(String.t) :: [String.t]
  def scan(interface_name) do
    GenServer.call(__MODULE__, {:scan, interface_name})
  end

  @doc """
    Restarts networking services. This will block.
  """
  def restart() do
    GenServer.call(__MODULE__, :restart_network, :infinity)
  end

  # GENSERVER STUFF
  def handle_call({:scan, interface_name}, _, target) do
     f = mod(target).scan(interface_name)
     {:reply, f, target}
  end

  def handle_call(:restart_network, _, target) do
    mod(target).restart
    {:reply, :ok, target}
  end

  # Behavior
  @type return_type :: :ok | {:error, term}
  @callback scan(String.t) :: [String.t]
  @callback start_interface(String.t) :: return_type
  @callback stop_interface(String.t) :: return_type
  @callback restart_interface(String.t) :: return_type
  @callback stop_all :: return_type
  @callback start_all :: return_type
  @callback start_link :: {:ok, pid}
end
