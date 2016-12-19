defmodule Uh do
  alias RPC.Spec.Notification
  alias RPC.Spec.Request
  alias RPC.Spec.Response
  alias Farmbot.Configurator.EventManager, as: EM
  import RPC.Parser
  use GenEvent
  require Logger
  import Farmbot.RPC.Requests

  # GenEvent Stuff
  def start_link, do: GenEvent.add_handler(EM, __MODULE__, [])
  def stop_link, do: GenEvent.remove_handler(EM, __MODULE__, [])
  def init([]), do: {:ok, []}

  def handle_event({:from_socket, message}, state) do
    # IO.inspect message
    message |> parse |> handle_socket
    {:ok, state}
  end
  # hack to ignore messages from myself here.
  def handle_event(_, state), do: {:ok, state}

  def handle_socket(
    %Request{id: id,
             method: "get_current_config",
             params: _})
  do
    Logger.debug ">> got request to get entire config file."
    {:ok, read} =  Farmbot.FileSystem.ConfigStorage.read_config_file
    thing = read |> Poison.decode!
    %Response{id: id, result: Poison.encode!(thing), error: nil}
    |> Poison.encode!
    |> send_socket
  end

  def handle_socket(%Request{} = request) do
    handle_request(request.method, request.params) |> respond(request)
  end

  def handle_socket(%Notification{} = notification) do
    Logger.debug ">> got an incoming RPC Notification: #{inspect notification}"
  end

  def handle_socket(%Response{id: _, result: "pong", error: _}) do
    nil
  end

  def handle_socket(%Response{} = response) do
    Logger.debug ">> got an incoming RPC Response: #{inspect response}"
  end

  def handle_socket(m) do
    Logger.debug ">> got an unhandled rpc message #{inspect m}"
  end

  defp respond(:ok, %Request{} = request) do
    Response.create(%{"id" => request.id, "result" => "ok", "error" => nil})
    |> Poison.encode! |> send_socket
  end

  defp respond({:error, _name, _reason}, %Request{} = request) do
    Logger.error ">> Error doing #{request.method}"
  end

  defp send_socket(json), do: EM.send_socket({:from_bot, json})
end
