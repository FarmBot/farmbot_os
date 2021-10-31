defmodule FarmbotOS.FarmEventWorker.RegimenEvent do
  @moduledoc """
  Periodically checks the current date versus the date that
  a regimen should be started.
  """
  require Logger
  use GenServer
  alias FarmbotOS.Asset

  @impl GenServer
  def init([event, args]) do
    send(self(), :checkup)
    {:ok, %{event: event, args: args}}
  end

  @impl GenServer
  def handle_info(:checkup, state) do
    send(self(), {:checkup, DateTime.utc_now()})
    {:noreply, state}
  end

  def handle_info({:checkup, now}, state) do
    start_time = state.event.start_time

    should_be_running? = DateTime.compare(start_time, now) == :lt

    if should_be_running? do
      Logger.debug(
        "Ensuring RegimenInstance exists for event: #{inspect(state.event)}"
      )

      send(self(), {:ensure_started})
      {:noreply, state}
    else
      send(self(), {:ensure_not_started})

      Process.send_after(
        self(),
        :checkup,
        state.args[:checkup_time_ms] || 15_000
      )

      {:noreply, state}
    end
  end

  def handle_info({:ensure_started}, state) do
    if Asset.get_regimen_instance(state.event) do
      send(self(), {:ensure_unchanged})
      {:noreply, state}
    else
      Logger.debug(
        "Creating RegimenInstance for event: #{inspect(state.event)}"
      )

      _regimen_instance =
        Asset.new_regimen_instance!(state.event, %{
          started_at: state.event.start_time
        })

      {:noreply, state, :hibernate}
    end
  end

  def handle_info({:ensure_not_started}, state) do
    regimen_instance = Asset.get_regimen_instance(state.event)

    if regimen_instance do
      Logger.debug(
        "RegimenInstance shouldn't exist for event: #{inspect(state.event)} Removing."
      )

      Asset.delete_regimen_instance!(regimen_instance)
      {:noreply, state, :hibernate}
    else
      {:noreply, state, :hibernate}
    end
  end

  def handle_info({:ensure_unchanged}, state) do
    regimen_instance = Asset.get_regimen_instance(state.event)
    start_time = state.event.start_time

    start_times_ok? =
      Map.equal?(
        Map.take(regimen_instance.started_at, [:year, :month, :day]),
        Map.take(start_time, [:year, :month, :day])
      )

    if start_times_ok? do
      {:noreply, state, :hibernate}
    else
      Logger.debug(
        "RegimenInstance start time changed for event: #{inspect(state.event)} Recreating."
      )

      Asset.delete_regimen_instance!(regimen_instance)
      Asset.new_regimen_instance!(state.event, %{started_at: start_time})
      {:noreply, state, :hibernate}
    end
  end
end
