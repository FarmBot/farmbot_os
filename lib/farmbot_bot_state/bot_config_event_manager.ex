defmodule Farmbot.BotState.EventManager do
  @moduledoc """
    Handles stuff like logging in to web services and what not.
  """
  use GenEvent
  require Logger

  def handle_event({:login,
    %{"email" => email,
      "network" => "ethernet",
      "password" => password,
      "server" => server,
      "tz" => timezone}}, parent)
  do
    Farmbot.BotState.update_config("timezone", timezone)
    Farmbot.BotState.add_creds({email,password,server})
    NetMan.connect(:ethernet, Farmbot.BotState)
    {:ok, parent}
  end

  def handle_event({:login,
    %{"email" => email,
      "network" => %{"psk" => psk, "ssid" => ssid},
      "password" => password,
      "server" => server,
      "tz" => timezone}}, parent)
  do
    Farmbot.BotState.update_config("timezone", timezone)
    Farmbot.BotState.add_creds({email,password,server})
    NetMan.connect({ssid, psk}, Farmbot.BotState)
    {:ok, parent}
  end

  def handle_event(event, parent) do
    Logger.warn("unhandled botstate event #{inspect event}")
    {:ok, parent}
  end
end
