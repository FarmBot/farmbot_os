defmodule Farmbot.BotState.LedWorker do
  @moduledoc "Flashes leds based on connection status."
  use GenServer
  alias Farmbot.System.Registry, as: FBR

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    FBR.subscribe(self())
    Farmbot.Leds.blue(:off)
    {:ok, %{}}
  end

  def handle_info({FBR, {:bot_state, %{informational_settings: %{connected: true}}}}, state) do
    Farmbot.Leds.blue(:solid)
    {:noreply, state}
  end

  def handle_info({FBR, {:bot_state, %{informational_settings: %{connected: false}}}}, state) do
    Farmbot.Leds.blue(:off)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
