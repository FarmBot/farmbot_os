defmodule Farmbot.Configurator.EventHandler do
  @moduledoc """
    Handles websocket to bot communication
  """
  require Logger
  alias Farmbot.Configurator.EventManager, as: EM

  # Public api
  @doc """
    Adds a socket to the handler
  """
  def add_socket(socket),
    do: GenEvent.call(EM, __MODULE__, {:add_socket, socket})

  @doc """
    Removes a socket to the handler
  """
  def remove_socket(socket),
    do: GenEvent.call(EM, __MODULE__, {:remove_socket, socket})

  @doc """
    Gets all the sockets
  """
  def sockets, do: GenEvent.call(EM, __MODULE__, :sockets)

  @doc """
    Starts the event handler.
  """
  def start_link do
    Logger.debug ">> a websocket event handler is starting"
    GenEvent.add_handler EM, __MODULE__, []
    {:ok, self}
  end

  @doc """
    Stops the event handler
  """
  def stop_link do
    Logger.debug ">> a websocket event handler is stopping"
    GenEvent.remove_handler(EM, __MODULE__, [])
  end

  def init(_args) do
    {:ok, []}
  end

  def handle_event({:from_bot, event}, sockets) do
    broadcast(sockets, {:from_bot, event})
    {:ok, sockets}
  end

  # we don't really care about anything else.
  def handle_event(_event, sockets), do: {:ok, sockets}

  # called from a socket instance
  def handle_call({:add_socket, socket}, sockets) do
    {:ok, :ok, [socket | sockets]}
  end

  # called from a socket instance
  def handle_call({:remove_socket, socket}, sockets) do
    {:ok, :ok, sockets -- [socket]}
  end

  def handle_call(:sockets, sockets), do: {:ok, sockets, sockets}
  def handle_call(_, sockets), do: {:ok, :unhandled, sockets}
  def terminate(_,_), do: :ok

  # Probably a better way to do this...
  defp broadcast(sockets, event) do
    Enum.each(sockets, fn(socket) ->
      send(socket, event)
    end)
  end
end
