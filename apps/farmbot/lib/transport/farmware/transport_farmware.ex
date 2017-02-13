defmodule Farmbot.Transport.Farmware do
  @moduledoc """
    Transport for exchanging celeryscript too Farmware packages.
  """
  use GenStage
  require Logger
  alias Farmbot.Transport.Farmware.TCP, as: Server

  @socket_port 5678 # TODO(Connor) make this some sort of configuration

  @doc """
    Starts the handler that watches the mqtt client
  """
  @spec start_link :: {:ok, pid}
  def start_link,
    do: GenStage.start_link(__MODULE__, [], name: __MODULE__)

  @spec init(any) :: {:consumer, any, subscribe_to: [Farmbot.Transport]}
  def init([]) do
    {:consumer, nil, subscribe_to: [Farmbot.Transport]}
  end

  def handle_events(events, _, server) do
    for event <- events do
      Logger.info("#{__MODULE__}: Got event: #{inspect event}")
    end
    {:noreply, [], server}
  end

  def handle_info({_from, event}, server) do
    # Send the event over the socket
    if server do
      GenServer.cast(server, event)
    end
    {:noreply, [], server}
  end

  def handle_call(:server_end, _, _) do
    {:reply, :ok, [], nil}
  end

  def handle_call(:farmware_start, _, _server) do
    {:ok, server} = Server.start_link
    {:reply, :ok, [], server}
  end

  def handle_call(:farmware_finish, _, server) do
    if server do
      :ok = Server.stop(server)
    end
    {:reply, :ok, [], nil}
  end

  @doc """
    Call when a farmware starts
  """
  def farmware_start(timeout \\ 11_000) do
    GenServer.call(__MODULE__, :farmware_start, timeout)
  end

  @doc """
    Call when a farmware finishes
  """
  def farmware_finish() do
    GenServer.call(__MODULE__, :farmware_finish)
  end

  @doc """
    Called when a tcp server finished
  """
  def server_finish() do
    GenServer.call(__MODULE__, :server_finish)
  end
end
