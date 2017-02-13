defmodule Farmbot.Transport.Farmware.TCP do
  @moduledoc """
    A tcp server for farmwares to connect to via a Redis type api
  """
  use GenServer
  require Logger
  alias Farmbot.CeleryScript.Command
  alias Farmbot.CeleryScript.Ast

  @doc """
    Start the tcp server
  """
  def start_link(timeout \\ 10_000), do: GenServer.start_link(__MODULE__, timeout, name: __MODULE__)

  # Initialize a tcp_server deal
  def init(timeout) do
    {:ok, socket} = :gen_tcp.listen(5678, [:binary, packet: 0, active: true, exit_on_close: false])
    case :gen_tcp.accept(socket, timeout) do
      {:ok, socket} -> {:ok, socket}
      {:error, reason} -> terminate(reason, socket)
    end
  end

  # This is where the DSL will live
  def handle_info({:tcp, socket, string}, socket) do
    handle_socket(String.trim(string), socket)
    {:noreply, socket}
  end

  # When the socket gets closed
  def handle_info({:tcp_closed, _socket}, socket) do
    Logger.debug "closed tcp socket"
    spawn fn() -> GenServer.stop(__MODULE__, :tcp_closed) end
    {:noreply, socket}
  end

  # Push the bots state to the farmware
  def handle_cast({:status, status}, socket) do
    # :gen_tcp.send(socket, Poison.encode!(status))
    {:noreply, socket}
  end

  # Ignore other things
  def handle_cast(_, socket), do: {:noreply, socket}

  # Cleanup
  def terminate(_reason, socket) do
    # Close the socket without making a mess
    :gen_tcp.shutdown(socket, :read_write)
    Farmbot.Transport.Farmware.server_finish
    {:ok, nil}
  end

  @spec handle_socket(binary, port) :: :ok | {:error, term}
  # IF we want to get an object out of the database
  defp handle_socket("GET DB." <> key, socket) do
    IO.inspect key
    {:ok, so} = Farmbot.Sync.load_recent_so()
    case Map.get(so, key |> String.trim |> String.to_atom) do
      nil -> :gen_tcp.send(socket, "Could not fine object!!\r\n")
      thing -> :gen_tcp.send(socket, Poison.encode!(thing) <> "\r\n")
    end
  end

  # IF we want to execute farmware
  defp handle_socket(string, socket) do
    with {:ok, json} <- Poison.decode(string), # Try to parse json
         %Ast{} = celery_script <- Ast.parse(json), # Try to turn it into CS
         do: Command.do_command(celery_script) # try to execute that command
       else _ -> :gen_tcp.send(socket, "unhandled!\r\n") # else say its broken
  end
end
