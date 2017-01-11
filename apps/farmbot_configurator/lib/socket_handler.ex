defmodule Farmbot.Configurator.SocketHandler do
  @moduledoc """
    Handles the websocket connection from a browser.
  """
  require Logger
  # Ignore the compiler warning here. I haven't quite figured out how i want to
  # fix it, its nothing bad.
  # this module doesn't exist at compile time, but when we hit run time
  # it does. I could make it an atom: :"Elixir.Farmbot.Transport.WebScoket",
  # but that is kind of ugly.
  alias Farmbot.Transport.WebSocket, as: WSTransport
  # alias Farmbot.Transport.Serialized, as: Ser

  @timeout 60000 # terminate if no activity for one minute
  @ping "\"ping\""
  @pong "\"pong\""
  @timer 2000

  # this is a cowboy thing
  @behaviour :cowboy_websocket_handler
  def init(_, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  # Called on websocket connection initialization.
  def websocket_init(_type, req, _options) do
    Logger.debug ">> encountered a new local websocket connection."
    # starts a ping pong deal, so the websocket doesnt close if the user takes
    # Too long to configurate.
    :erlang.start_timer(@timer, self(), [])

    # start the transport into the main Farmbot application.
    # This is where state updates, celeryscripts, logs, etc come from.
    {:ok, stage} = transport().start_link(self())

    # i dont actually remember what req is, but we don't use it.
    {:ok, req, stage, @timeout}
  end

  # don't response to pings or anything, its here to keep us alive.
  # i guess instead of running a timer i could just use this to send teh next
  # ping, but that sounds like it could suck up some bandwidth.
  def websocket_handle({:text, @pong}, req, stage), do: {:ok, req, stage}

  # messages from the browser.
  def websocket_handle({:text, m}, req, stage) do
    Logger.debug ">> can't handle data from websocket: #{inspect m}"
    {:ok, req, stage}
  end

  # this is the ping pong nonsense.
  def websocket_info({:timeout, _, []}, req, stage) do
    :erlang.start_timer(@timer, self(), [])
    {:reply, {:text, @ping}, req, stage}
  end

  # Belive it or not, this is a log message lol.
  def websocket_info(
    [log: %{channels: _, created_at: _, message: _, meta: _} = m],
    req, stage), do: {:reply, {:text, Poison.encode!(m)}, req, stage}

  # the transport uses GenStage, which is made for a queue of events,
  # we only ever have one message at a time, but this might not always be true,
  # for now we can infer that if it is a list with one item, its probably an
  # event from the main farmbot application.
  def websocket_info([{:emit, message}], req, stage) do
    case Poison.encode(message) do
       {:ok, json} -> {:reply, {:text, json}, req, stage}
       _ -> {:ok, req, stage}
    end
  end

  def websocket_info([bot_state], req, stage) do
    Poison.encode(bot_state)
    {:ok, req, stage}
  end

  # ignore unhandled messages.
  def websocket_info(message, req, stage) do
    Logger.warn ">> got an unhandled websocket message: #{inspect message}"
    {:ok, req, stage}
  end

  def websocket_terminate(_reason, _req, _stage) do
    Logger.debug ">> is closing a websocket connection."
    # make sure to stop anything when we finish up.
    transport().stop_link(self())
  end

  # little HACK to minimize compiler warnings.
  # unfortunately this makes us lose autocomplete. /shrug
  defp transport, do: WSTransport
end
