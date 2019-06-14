defmodule FarmbotCore.FarmEventWorker.RegimenEvent do
  @moduledoc """
  Periodicly checks the current date versus the date that
  a regimen should be started. 
  """
  require Logger
  use GenServer
  alias FarmbotCore.Asset

  @impl GenServer
  def init([event, args]) do
    send self(), :checkup
    {:ok, %{event: event, args: args}}
  end

  @impl GenServer
  def handle_info(:checkup, state) do
    send self(), {:checkup, DateTime.utc_now()}
    {:noreply, state}    
  end

  def handle_info({:checkup, now}, state) do
    start_time = state.event.start_time
    
    should_be_running? = Map.equal?(
      Map.take(now, [:year, :month, :day]),
      Map.take(start_time, [:year, :month, :day])
    )

    if should_be_running? do
      Logger.debug "Ensuring RegimenInstance exists for event: #{inspect(state.event)}"
      send self(), {:ensure_started, now}
      {:noreply, state}
    else
      Process.send_after(self(), :checkup, state.args[:checkup_time_ms] || 15_000)
      {:noreply, state}
    end
  end

  def handle_info({:ensure_started, now}, state) do
    if Asset.get_regimen_instance(state.event) do
      Logger.debug "RegimenInstance already exists for event: #{inspect(state.event)}"
      {:noreply, state, :hibernate}
    else
      Logger.debug "Creating RegimenInstance for event: #{inspect(state.event)}"
      _regimen_instance = Asset.new_regimen_instance!(state.event, %{started_at: now})
      {:noreply, state, :hibernate}
    end
  end
end