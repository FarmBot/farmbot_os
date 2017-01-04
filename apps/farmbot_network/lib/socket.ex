defmodule Farmbot.Network.ConfigSocket do
  @moduledoc """
    Handles the websocket connection from the frontend.
  """
  alias Farmbot.Configurator.EventManager, as: EM
  alias Farmbot.FileSystem.ConfigStorage, as: CS
  alias Farmbot.Network
  alias Farmbot.Auth
  use GenEvent
  require Logger

  def init([]), do: {:ok, []}

  def handle_event({:from_socket, message}, state) do
    message |> handle_socket
    {:ok, state}
  end
  # hack to ignore messages from myself here.
  def handle_event(_, state), do: {:ok, state}

  def handle_socket("pong") do
    nil
  end

  def handle_socket(thing) do
    Logger.warn "socket handler is broken! #{inspect thing}"
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
