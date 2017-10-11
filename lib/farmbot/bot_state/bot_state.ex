defmodule Farmbot.BotState do
  use GenStage
  require Logger

  defstruct mcu_params: %{},
            jobs: %{},
            location_data: %{},
            pins: %{},
            configuration: %{},
            informational_settings: %{},
            user_env: %{},
            process_info: %{}

  def start_link(opts) do
    GenStage.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    {:producer_consumer, struct(__MODULE__), subscribe_to: [Farmbot.Firmware]}
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
