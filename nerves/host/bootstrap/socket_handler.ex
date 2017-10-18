defmodule SocketHandler do
  require Logger

  @timeout 60_000

  @behaviour :cowboy_websocket_handler

  def init(_, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  def websocket_init(_type, req, _options) do
    Logger.info "Encountered a new local websocket connection."
    {:ok, req, nil, @timeout}
  end

  def websocket_handle({:text, data}, req, state), do: {:reply, data, req, state}

  def websocket_info(_, req, state) do
    {:ok, req, state}
    # {:reply, {:text, @ping}, req, stage}
  end


  def websocket_terminate(_reason, _req, _stage) do
    Logger.info "Closing a websocket connection."
  end
end
