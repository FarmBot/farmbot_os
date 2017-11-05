defmodule Farmbot.BotState.Transport.GenMQTT do
  @moduledoc "MQTT BotState Transport."
  use GenStage
  require Logger
  alias Farmbot.BotState.Transport.GenMQTT.Client

  @doc false
  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    token = Farmbot.System.ConfigStorage.get_config_value(:string, "authorization", "token")
    {:ok, %{bot: device, mqtt: mqtt_server}} = Farmbot.Jwt.decode(token)
    {:ok, client} = Client.start_link(device, token, mqtt_server)
    {:consumer, {%{client: client}, nil}, subscribe_to: [Farmbot.BotState, Farmbot.Logger]}
  end

  def handle_events(events, {pid, _}, state) do
    case Process.info(pid)[:registered_name] do
      Farmbot.Logger -> handle_log_events(events, state)
      Farmbot.BotState -> handle_bot_state_events(events, state)
    end
  end

  def handle_log_events(logs, {%{client: client} = internal_state, old_bot_state}) do
    for log <- logs do
      Client.push_bot_log(client, log)
    end

    {:noreply, [], {internal_state, old_bot_state}}
  end

  def handle_bot_state_events(events, {%{client: client} = internal_state, _old_bot_state}) do
    new_bot_state = List.last(events)

    Client.push_bot_state(client, new_bot_state)
    # if new_bot_state != old_bot_state do
    # end
    {:noreply, [], {internal_state, new_bot_state}}
  end
end
