defmodule Farmbot.Configurator.SocketHandler do
  @moduledoc """
    Handles the websocket connection from a browser.
  """
  require Logger
  @behaviour :cowboy_websocket_handler
  @timeout 60000 # terminate if no activity for one minute
  @ping "\"ping\""
  @pong "\"pong\""

  def init(_, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  # Called on websocket connection initialization.
  def websocket_init(_type, req, _options) do
    Logger.debug ">> encountered a new local websocket connection."
    :erlang.start_timer(1000, self, [])
    {:ok, stage} = Farmbot.Transport.WebSocket.start_link(self)
    {:ok, req, stage, @timeout}
  end

  def websocket_handle({:text, @pong}, req, stage), do: {:ok, req, stage}

  # messages from the browser.
  def websocket_handle({:text, m}, req, stage) do
    Logger.debug ">> can't handle data from websocket: #{inspect m}"
    {:ok, req, stage}
  end

  def websocket_info({:timeout, _, []}, req, stage) do
    :erlang.start_timer(1000, self, [])
    {:reply, {:text, @ping}, req, stage}
  end

  def websocket_info(
    [log: %{channels: _, created_at: _, message: _, meta: _} = m],
    req, stage), do: {:reply, {:text, Poison.encode!(m)}, req, stage}


  def websocket_info([message], req, stage) do
    case Poison.encode(message) do
       {:ok, json} -> {:reply, {:text, json}, req, stage}
       _ -> {:ok, req, stage}
    end
  end

  def websocket_info(message, req, stage), do: {:ok, req, stage}

  def websocket_terminate(_reason, _req, _stage) do
    Logger.debug ">> is closing a websocket connection."
  end
end
