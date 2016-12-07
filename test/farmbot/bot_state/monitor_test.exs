defmodule Farmbot.BotState.MonitorTest do
  use ExUnit.Case, async: false
  defmodule TempStateTracker do
    @moduledoc false
    use GenEvent
    def handle_event({:dispatch, state},_), do: {:ok, state}
    def handle_call(:state, state), do: {:ok, state, state}
    def state(name \\ __MODULE__), do: GenEvent.call(Farmbot.BotState.EventManager, name, :state)

    def start(name \\ __MODULE__) do
      Farmbot.BotState.Monitor.add_handler(name)
      {:ok, self()}
    end

    def stop(name \\ __MODULE__) do
      Farmbot.BotState.Monitor.remove_handler(name)
    end
  end

  test "adds and removes a handler to the monitor" do
    {:ok, _pid} = TempStateTracker.start
    state = get_state
    assert is_map(state)

    TempStateTracker.stop
    new = get_state
    assert {:error, :not_found} == new
  end

  defp get_state() do
    Process.sleep(10)
    TempStateTracker.state()
  end


end
