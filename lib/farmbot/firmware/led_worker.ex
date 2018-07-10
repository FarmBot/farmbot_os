defmodule Farmbot.Firmware.LedWorker do
  @moduledoc "Flashes leds based on e-stop status."
  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    Farmbot.System.Registry.subscribe(self())
    Farmbot.Leds.red(:solid)
    {:ok, %{}}
  end

  def handle_info(:bot_state, %{informational_settings: %{locked: true}}, state) do
    Farmbot.Leds.yellow(:slow_blink)
    {:noreply, state}
  end

  def handle_info(
        :bot_state,
        %{informational_settings: %{locked: false}},
        state
      ) do
    Farmbot.Leds.yellow(:off)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
