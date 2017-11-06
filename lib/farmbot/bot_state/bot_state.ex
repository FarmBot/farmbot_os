defmodule Farmbot.BotState do
  @moduledoc "JSON Serializable state tree that gets pushed over variour transports."

  use GenStage
  require Logger
  @version Mix.Project.config()[:version]
  @commit Mix.Project.config()[:commit]
  @target Mix.Project.config()[:target]
  @env Mix.env()

  alias Farmbot.CeleryScript.AST

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
      subscribe_to: [Farmbot.Firmware, Farmbot.System.ConfigStorage.Dispatcher], dispatcher: GenStage.BroadcastDispatcher
    }
  end

  def handle_events(events, _from, state) do
    state = do_handle(events, state)
    {:noreply, [state], state}
  end

  def handle_call(:force_state_push, _from, state) do
    {:reply, state, [state], state}
  end

  def handle_call({:emit, ast}, _from, state) do
    {:reply, :ok, [{:emit, ast}], state}
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
