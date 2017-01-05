alias Experimental.GenStage
defmodule Farmbot.Transport.WebSocket do
  @moduledoc """
    Transport for exchanging celeryscript over websockets.
  """
  use GenStage
  require Logger
  alias Farmbot.Transport.Serialized, as: Ser

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

  def handle_events(events, _, socket) do
    send(socket, events)
    {:noreply, [], socket}
  end

  @spec stop_link(pid) :: :ok
  def stop_link(socket) do
    GenStage.stop(socket)
  end
end
