defmodule BotState.EventManager do
  @doc """
    Don't worry about compiler warnings in this module. I need to add some things
    to FakeNerves
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
    BotState.update_config("timezone", timezone)
    BotState.add_creds({email,password,server})
    NetMan.connect(:ethernet, BotState)
    {:ok, parent}
  end

  def handle_event({:login,
    %{"email" => email,
      "network" => %{"psk" => psk, "ssid" => ssid},
      "password" => password,
      "server" => server,
      "tz" => timezone}}, parent)
  do
    BotState.update_config("timezone", timezone)
    BotState.add_creds({email,password,server})
    NetMan.connect({ssid, psk}, BotState)
    {:ok, parent}
  end

  def handle_event(event, parent) do
    Logger.debug("#{inspect event}")
    {:ok, parent}
  end
end
