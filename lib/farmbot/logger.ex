defmodule Farmbot.Logger do
  @moduledoc "Logger."
  use GenStage
  alias Farmbot.Log

  @doc "Start Logging Services."
  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    Logger.add_backend(Logger.Backends.Farmbot, [])

    {
      :producer_consumer,
      %{meta: %Log.Meta{x: -1, y: -1, z: -1}},
      subscribe_to: [Farmbot.Firmware]
    }
  end

  def handle_demand(_, state) do
    {:noreply, [], state}
  end

  def handle_events(gcodes, _from, state) do
    {x, y, z} =
      Enum.find_value(gcodes, fn code ->
        case code do
          {:report_current_position, x, y, z} -> {x, y, z}
          _ -> false
        end
      end)

    {:noreply, [], %{state | meta: %{state.meta | x: x, y: y, z: z}}}
  end

  def handle_info({:log, log}, state) do
    {:noreply, [%{log | meta: state.meta}], state}
  end

  def terminate(_, _state) do
    Logger.remove_backend(Logger.Backends.Farmbot)
  end
end
