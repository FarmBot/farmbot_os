defmodule Farmbot.Configurator.SocketHandler do
  @moduledoc """
    Handles the websocket connection from a browser.
  """
  alias Farmbot.Configurator.EventManager, as: EM
  alias Farmbot.Configurator.EventHandler, as: EH
  require Logger
  @behaviour :cowboy_websocket_handler
  @timeout 60000 # terminate if no activity for one minute

  def init(_, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  #Called on websocket connection initialization.
  def websocket_init(_type, req, _options) do
    Logger.debug ">> encountered a new local websocket connection."
    # Logger.add_backend(Farmbot.Configurator.Logger, [self])
    :erlang.start_timer(1000, self, [])
    # :ok = EH.start_link(self)
    :ok = EH.add_socket(self)
    {:ok, req, [], @timeout}
  end

  # Handle other messages from the browser - don't reply
  def websocket_handle({:text, message}, req, state) do
    message |> Poison.decode |> handle_message
    {:ok, req, state}
  end

  def websocket_info({:timeout, _, []}, req, state) do
    :erlang.start_timer(1000, self, [])
    {:reply, {:text, ping_message}, req, state}
  end

  def websocket_info({:from_bot, event}, req, state) do
    {:reply, {:text, event}, req, state}
  end

  def websocket_info(message, req, state) do
    Logger.debug ">> got an info message: #{inspect message}"
    {:ok, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    Logger.debug ">> is closing a websocket connection."
    # Logger.remove_backend(Farmbot.Configurator.Logger,[])
    :ok = EH.remove_socket(self)
    :ok
  end

  def handle_message({:ok, m}), do: GenEvent.notify(EM, {:from_socket, m})
  def handle_message(_), do: Logger.warn ">> Got unhandled websocket message!"
  
  defp ping_message do
    lazy_id = :os.system_time(:seconds) |> Integer.to_string
    Poison.encode! %{"id" => lazy_id, "method" => "ping", "params" => [] }
  end
end
