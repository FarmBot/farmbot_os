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
      struct(__MODULE__),
      subscribe_to: [Farmbot.Firmware], dispatcher: GenStage.BroadcastDispatcher
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

  defp do_handle([{key, diff} | rest], state) do
    state = %{state | key => Map.merge(Map.get(state, key), diff)}
    Logger.debug "Got #{key} => #{inspect diff} #{inspect state}"
    do_handle(rest, state)
  end
end
