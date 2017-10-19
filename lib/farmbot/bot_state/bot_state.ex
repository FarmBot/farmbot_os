defmodule Farmbot.BotState do
  use GenStage
  require Logger
  @version Mix.Project.config()[:version]
  @commit Mix.Project.config()[:commit]
  @target Mix.Project.config()[:target]
  @env Mix.env()

  defstruct mcu_params: %{},
            jobs: %{},
            location_data: %{},
            pins: %{},
            configuration: %{},
            informational_settings: %{
              controller_version: @version,
              commit: @commit,
              target: @target,
              env: @env
            },
            user_env: %{},
            process_info: %{}

  def start_link(opts) do
    GenStage.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    {:producer_consumer, struct(__MODULE__), subscribe_to: [Farmbot.Firmware],
                                             dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_events(events, _from, state) do
    state = do_handle(events, state)
    {:noreply, [state], state}
  end

  defp do_handle([], state), do: state

  defp do_handle([{key, diff} | rest], state) do
    state = %{state | key => Map.merge(Map.get(state, key), diff)}
    do_handle(rest, state)
  end
end
