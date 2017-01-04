defmodule Farmbot.Network.ConfigSocket do
  @moduledoc """
    Handles the websocket connection from the frontend.
  """
  alias RPC.Spec.Notification
  alias RPC.Spec.Request
  alias RPC.Spec.Response
  import RPC.Parser

  alias Farmbot.Configurator.EventManager, as: EM
  alias Farmbot.FileSystem.ConfigStorage, as: CS
  alias Farmbot.Network
  alias Farmbot.Auth
  use GenEvent
  require Logger

  def init([]), do: {:ok, []}

  def handle_event({:from_socket, message}, state) do
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
    {:ok, read} =  CS.read_config_file
    thing = read |> Poison.decode!
    %Response{id: id, result: Poison.encode!(thing), error: nil}
    |> Poison.encode!
    |> send_socket
  end

  def handle_socket(
    %Request{id: id,
             method: "get_network_interfaces",
             params: _})
  do
    # {hc, 0} = System.cmd("iw", ["wlan0", "scan", "ap-force"])
    # #FIXME!!
    # interfaces = [
    #   %{name: "wlan0", type: "wireless", ssids: hc |> clean_ssid},
    #   %{name: "eth0",  type: "ethernet"}
    # ]
    # %Response{id: id, result: Poison.encode!(interfaces), error: nil}
    # |> Poison.encode!
    # |> send_socket
    interfaces = []
    %Response{id: id, result: Poison.encode!(interfaces), error: nil}
    |> Poison.encode!
    |> send_socket
  end

  def handle_socket(
    %Request{id: id,
             method: "upload_config_file",
             params: [%{"config" => config}]})
  do
    # replace the old config file with the new one.
    _f = CS.replace_config_file(config)
    %Response{id: id, result: "OK", error: nil}
    |> Poison.encode!
    |> send_socket
  end

  def handle_socket(
    %Request{id: id,
             method: "try_log_in",
             params: _})
  do
    # Configurator is done configurating.
    Logger.debug ">> has been configurated! going to try to log in."
    %Response{id: id, result: "OK", error: nil}
    |> Poison.encode!
    |> send_socket
    # this needs to be spawned because it is inside of an event which results in
    # event handler waiting for networking to restart
    # and networking waiting for this app to finish its event
    # which is waiting for networking to wait for this event etc.
    spawn fn() -> Network.restart end
  end

  def handle_socket(
    %Request{id: id,
             method: "web_app_creds",
             params: [%{"email" =>  email,
                        "pass" => pass,
                        "server" => server}]})
  do
    Auth.interim(email, pass, server)
    %Response{id: id, result: "OK", error: nil}
    |> Poison.encode!
    |> send_socket
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

  defp send_socket(json), do: EM.send_socket({:from_bot, json})

  defp clean_ssid(hc) do
    hc
    |> String.replace("\t", "")
    |> String.replace("\\x00", "")
    |> String.split("\n")
    |> Enum.filter(fn(s) -> String.contains?(s, "SSID") end)
    |> Enum.map(fn(z) -> String.replace(z, "SSID: ", "") end)
    |> Enum.filter(fn(z) -> String.length(z) != 0 end)
  end

  def terminate(_,_) do
    Logger.debug "websocket died."
  end
end
