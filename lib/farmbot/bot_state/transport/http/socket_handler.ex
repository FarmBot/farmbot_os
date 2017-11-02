defmodule Farmbot.BotState.Transport.HTTP.SocketHandler do
  @moduledoc """
  Handles the websocket connection from a browser.
  """

  require Logger
  alias Farmbot.BotState.Transport.HTTP
  alias Farmbot.BotState


  @timeout 60_000

  @behaviour :cowboy_websocket_handler

  def init(blah, req, opts) do
    conn = Plug.Adapters.Cowboy.Conn.conn(req, :tcp)
    require IEx; IEx.pry
    {:upgrade, :protocol, :cowboy_websocket}
  end

  # Called on websocket connection initialization.
  def websocket_init(_type, req, _options) do
    conn = Plug.Adapters.Cowboy.Conn.conn(req, :tcp)
    require IEx; IEx.pry
    case Farmbot.BotState.Transport.HTTP.AuthPlug.handle_prod(conn) do
      {_conn, _, _} -> {:shutdown, req}
      _ ->
        Logger.info "Websocket connect."
        HTTP.subscribe()
        {:ok, req, nil, @timeout}
    end
  end

  # def websocket_handle({:text, @pong}, req, state), do: {:ok, req, state}

  def websocket_info({Farmbot.Logger, logs}, req, state) do
    msg = %{kind: "log", body: logs} |> Poison.encode!
    {:reply, {:text, msg}, req, state}
  end

  def websocket_info({BotState, bot_state}, req, state) do
    msg = %{kind: "bot_state", body: bot_state} |> Poison.encode!
    {:reply, {:text, msg}, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    Logger.debug "Closed websocket connection."
    HTTP.unsubscribe()
  end

end
