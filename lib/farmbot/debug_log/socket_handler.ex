defmodule Farmbot.DebugLog.SocketHandler do
  @moduledoc """
    Handles the websocket connection from a browser.
  """

  defmodule Handler do
    @moduledoc false
    use GenEvent

    def init(pid) do
      {:ok, pid}
    end

    def handle_event({module, string}, pid) do
      send pid, "[#{module}]: #{string}"
      {:ok, pid}
    end
  end

  require Logger
  alias Farmbot.CeleryScript.Ast.Context

  @timeout :infinity

  # this is a cowboy thing
  @behaviour :cowboy_websocket_handler
  def init(_, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  # Called on websocket connection initialization.
  def websocket_init(_type, req, _options) do
    :ok = GenEvent.add_handler(Farmbot.DebugLog, Handler, self())
    state = []
    {:ok, req, state, @timeout}
  end

  # messages from the browser.
  def websocket_handle({:text, m}, req, state) do
    case Poison.decode(m) do
      {:ok, json} ->
        handle_json(json)
      {:error, _reason} ->
        Logger.info ">> Debug log got non json"
    end
    {:ok, req, state}
  end

  def websocket_info(info, req, state) when is_binary(info) do
    {:reply, {:text, "#{inspect info}"}, req, state}
  end

  # ignore unhandled messages.
  def websocket_info(message, req, state) do
    Logger.info ">> got an unhandled websocket message: #{inspect message}"
    {:ok, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    GenEvent.remove_handler(Farmbot.DebugLog, Handler, [])
  end

  defp handle_json(%{"to_firmware" => gcode}) do
    Farmbot.Serial.Handler.write(Context.new().serial, gcode)
  end

  defp handle_json(m) do
    Logger.info ">> can't handle data from websocket: #{inspect m}"
  end
end
