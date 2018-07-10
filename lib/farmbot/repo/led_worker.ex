defmodule Farmbot.Repo.LedWorker do
  @moduledoc "Flashes leds based on sync status."
  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    Farmbot.System.Registry.subscribe(self())
    {:ok, %{}}
  end

  def handle_info(
        :bot_state,
        %{informational_settings: %{sync_status: :sync_now}},
        state
      ) do
    Farmbot.Leds.green(:slow_blink)
    {:noreply, state}
  end

  def handle_info(
        :bot_state,
        %{informational_settings: %{sync_status: :syncing}},
        state
      ) do
    Farmbot.Leds.green(:fast_blink)
    {:noreply, state}
  end

  def handle_info(
        :bot_state,
        %{informational_settings: %{sync_status: :synced}},
        state
      ) do
    Farmbot.Leds.green(:solid)
    {:noreply, state}
  end

  def handle_info(
        :bot_state,
        %{informational_settings: %{sync_status: :sync_error}},
        state
      ) do
    Farmbot.Leds.green(:slow_blink)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
