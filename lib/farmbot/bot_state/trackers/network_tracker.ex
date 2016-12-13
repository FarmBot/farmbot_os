defmodule Farmbot.BotState.Network do
  @moduledoc """
    Light wrapper for Farmbot Networking.
  """

  require Logger
  alias Farmbot.StateTracker
  alias Farmbot.BotState
  @behaviour StateTracker
  use StateTracker,
      name: __MODULE__,
      model: [
        connected?: false,
        connection: nil
      ]

  @type args :: any
  @type connection :: nil | :ethernet | {String.t, String.t}
  @type t :: %__MODULE__.State{
    connected?: boolean,
    connection: connection
  }
  @spec load(args) :: {:ok, t}
  def load(_) do
    NetMan.put_pid(__MODULE__)
    case get_config(:connection) do
      {:ok, connection} ->
        :ok = start_connection(connection)
        f = %State{connected?: false, connection: connection}
        {:ok, f}
      _ ->
        # Starts configurator (Host APD)
        :ok = start_connection(nil)
        f = %State{connected?: false, connection: nil}
        {:ok, f}
    end
  end

  @spec start_connection(connection) :: :ok | {:error, atom}
  defp start_connection(connection) do
    NetMan.connect(connection, __MODULE__)
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.warn ">> got an unhandled call in " <>
                 "Network State tracker: #{inspect event}"
    dispatch :unhandled, state
  end

  # for development mode
  def handle_cast({:connected, :dev, ip_address}, %State{} = state) do
    GenServer.cast(BotState.Configuration,
                  {:update_info, :private_ip, ip_address})
    GenServer.cast(BotState.Authorization, :try_log_in)
    new_state = %State{state | connected?: true, connection: :dev}
    # TODO: Config file
    dispatch new_state
  end

  def handle_cast({:connected, connection, ip_address}, %State{} = state) do
    Process.sleep(2000) # I DONT KNOW WHY THIS HAS TO BE HERE
    BotState.set_time
    GenServer.cast(BotState.Configuration,
                  {:update_info, :private_ip, ip_address})
    GenServer.cast(BotState.Authorization, :try_log_in)
    new_state = %State{state | connected?: true, connection: connection}
    # TODO: Config file
    dispatch new_state
  end

  def handle_cast(event, %State{} = state) do
    Logger.warn ">> got an unhandled cast in " <>
                "Network State tracker: #{inspect event}"
    dispatch state
  end
end
