defmodule Farmbot.Transport.WebSocket do
  @moduledoc """
    Transport for exchanging celeryscript over websockets.
  """
  use GenStage
  require Logger

  # GENSTAGE HACK
  @spec handle_call(any, any, any) :: {:reply, any, any}
  @spec handle_cast(any, any) :: {:noreply, any}
  @spec handle_info(any, any) :: {:noreply, any}
  @spec init(any) :: {:ok, any}
  @spec handle_events(any, any, any) :: no_return

  # TODO(Connor) THIS IS BACKWRDS
  # Configurator starts this module, and it should be the other way.
  @doc """
    Starts a stage for a websocket handler.
  """
  @spec start_link(pid) :: {:ok, pid}
  def start_link(socket) do
    GenStage.start_link(__MODULE__, socket)
  end

  def init(socket) do
    {:consumer, socket, subscribe_to: [Farmbot.Transport]}
  end

  # TODO(Connor): these are misleading
  def handle_events(events, _, socket) do
    send(socket, events)
    {:noreply, [], socket}
  end

  def handle_info({_from, event}, socket) do
    send(socket, [event])
    {:noreply, [], socket}
  end

  @spec stop_link(pid) :: :ok
  def stop_link(socket) do
    GenStage.stop(socket)
  end
end
