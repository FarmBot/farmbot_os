alias Farmbot.RPC.Transport.GenMqtt.Client, as: Client
defmodule Farmbot.RPC.Transport.GenMqtt.Handler do
   
  @moduledoc """
    Makes sure MQTT stays alive and receives the Auth Token.
  """
  use GenServer
  require Logger

  def init(_args) do
    Process.flag(:trap_exit, true)
    case Farmbot.Auth.get_token |> Token.create do
      {:ok, %Token{} = token} ->
        {:ok, {token, start_client(token)}}
      _ ->
        {:ok, {nil, nil}}
    end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec start_client(Token.t) :: pid
  defp start_client(%Token{} = token) do
    # Log somethingwarn "Starting MQTT Client"
    {:ok, pid} = Client.start_link(token)
    pid
  end

  @spec stop_client(pid) :: :ok
  defp stop_client(pid) do
    GenServer.stop(pid, :new_token)
  end

  def handle_cast({:emit, binary}, {%Token{} = token, pid})
  when is_pid(pid) do
    send(Client, {:emit, binary})
    {:noreply, {token, pid}}
  end

  def handle_cast({:emit, _binary}, state) do
    # Save messages when offline maybe?
    {:noreply, state}
  end

  # We got a token and are not connected to mqtt yet.
  def handle_info({:authorization, maybe_token}, {_, nil}) do
    token = Token.create!(maybe_token)
    {:noreply, {token, start_client(token)}}
  end

  def handle_info({:authorization, maybe_token}, {_, pid})
  when is_pid(pid) do
    token = Token.create!(maybe_token)
    stop_client(pid)
    {:noreply, {token, start_client(token)}}
  end

  def handle_info({:EXIT, pid, _reason}, {%Token{} = token, client})
  when client == pid do
    # restart the client if it dies.
    {:noreply, {token, start_client(token)}}
  end

  def handle_info(info, pid_or_nil) do
    # Log somethingwarn("#{inspect info}")
    {:noreply, pid_or_nil}
  end

  @spec emit(binary) :: :ok
  @doc """
    Emits a message over the transport. Should be an RPC command, but there is
    no check for that.
  """
  def emit(binary) do
    GenServer.cast(__MODULE__, {:emit, binary})
  end
end
