defmodule Farmbot.BotState.Transport.GenMQTT do
  @moduledoc "MQTT BotState Transport."
  use GenStage
  use Farmbot.Logger
  alias Farmbot.BotState.Transport.GenMQTT.Client
  alias Farmbot.CeleryScript.AST

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
      if log.module == nil or Module.split(log.module || Elixir.Logger) |> List.first == "Farmbot" do
        location_data = Map.get(old_bot_state || %{}, :location_data, %{position: %{x: -1, y: -1, z: -1}})
        meta = %{type: log.level, x: nil, y: nil, z: nil}
        log_without_pos = %{meta: meta, channels: log.meta[:channels] || [], message: log.message}
        log = add_position_to_log(log_without_pos, location_data)
        Client.push_bot_log(client, log)
      end
    end

    {:noreply, [], {internal_state, old_bot_state}}
  end

  def handle_bot_state_events([event | rest], {%{client: client} = internal_state, old_bot_state}) do
    case event do
      {:emit, %AST{} = ast} ->
        Client.emit(client, ast)
        handle_bot_state_events(rest, {internal_state, old_bot_state})
      new_bot_state ->
        Client.push_bot_state(client, new_bot_state)
        handle_bot_state_events(rest, {internal_state, new_bot_state})
    end
  end

  def handle_bot_state_events([], {internal, bot_state}) do
    {:noreply, [], {internal, bot_state}}
  end

  defp add_position_to_log(%{meta: meta} = log, %{position: pos}) do
    new_meta = Map.merge(meta, pos)
    %{log | meta: new_meta}
  end
end
