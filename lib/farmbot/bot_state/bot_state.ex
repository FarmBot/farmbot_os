defmodule Farmbot.BotState do
  @moduledoc "JSON Serializable state tree that gets pushed over variour transports."

  use GenStage
  @version Mix.Project.config()[:version]
  @commit Mix.Project.config()[:commit]
  @target Mix.Project.config()[:target]
  @env Mix.env()

  alias Farmbot.CeleryScript.AST
  use Farmbot.Logger

  defstruct mcu_params: %{},
            jobs: %{},
            location_data: %{
              position: %{x: -1, y: -1, z: -1}
            },
            pins: %{},
            configuration: %{},
            informational_settings: %{
              controller_version: @version,
              commit: @commit,
              target: @target,
              env: @env,
              sync_status: :sync_now,
            },
            user_env: %{},
            process_info: %{}

  @doc "Get a current pin value."
  def get_pin_value(num) do
    GenStage.call(__MODULE__, {:get_pin_value, num})
  end

  @valid_sync_status [ :locked, :maintenance, :sync_error, :sync_now, :synced, :syncing, :unknown]
  @doc "Set the sync status above ticker to a message."
  def set_sync_status(cmd) when cmd in @valid_sync_status do
    GenStage.call(__MODULE__, {:set_sync_status, cmd})
  end

  @doc "Forces a state push over all transports."
  def force_state_push do
    GenStage.call(__MODULE__, :force_state_push)
  end

  @doc "Emit an AST."
  def emit(%AST{} = ast) do
    GenStage.call(__MODULE__, {:emit, ast})
  end

  def get_user_env do
    # GenStage.call(__MODULE__, :get_user_env)
    %{}
  end

  @doc false
  def start_link() do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {
      :producer_consumer,
      struct(__MODULE__, configuration: Farmbot.System.ConfigStorage.get_config_as_map()["settings"]),
      subscribe_to: [Farmbot.Firmware, Farmbot.System.ConfigStorage.Dispatcher],
      dispatcher: GenStage.BroadcastDispatcher
    }
  end

  def handle_events(events, _from, state) do
    # Logger.busy 3, "begin handle bot state events"
    state = do_handle(events, state)
    # Logger.success 3, "Finish handle bot state events"
    {:noreply, [state], state}
  end

  def handle_call({:get_pin_value, pin}, _from, state) do
    case state.pins[pin] do
      nil ->
        {:reply, {:error, :unknown_pin}, [], state}
      %{value: value} ->
        {:reply, {:ok, value}, [], state}
    end
  end

  def handle_call(:force_state_push, _from, state) do
    {:reply, state, [state], state}
  end

  def handle_call({:emit, ast}, _from, state) do
    {:reply, :ok, [{:emit, ast}], state}
  end

  def handle_call({:set_sync_status, status}, _, state) do
    new_info_settings = %{state.informational_settings | sync_status: status}
    new_state = %{state | informational_settings: new_info_settings}
    {:reply, :ok, [new_state], new_state}
  end

  defp do_handle([], state), do: state

  defp do_handle([{:config, "settings", key, val} | rest], state) do
    new_config = Map.put(state.configuration, key, val)
    new_state = %{state | configuration: new_config}
    do_handle(rest, new_state)
  end

  defp do_handle([{:config, _, _, _} | rest], state) do
    do_handle(rest, state)
  end

  defp do_handle([{key, diff} | rest], state) do
    state = %{state | key => Map.merge(Map.get(state, key), diff)}
    do_handle(rest, state)
  end
end
