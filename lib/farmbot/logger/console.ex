defmodule Farmbot.Logger.Console do
  @moduledoc false

  use GenStage
  @default_log_verbosity 3

  @doc "Filter by verbosity."
  def set_verbosity_level(verbosity_filter) do
    GenStage.call(__MODULE__, {:set_verbosity_level, verbosity_filter})
  end

  @doc "Filter by level."
  def filter_level(level) when level in [:debug, :info, :busy, :success, :warn, :error] do
    GenStage.call(__MODULE__, {:filter_level, level})
  end

  @doc "Remove a level filter."
  def remove_level_filter(level) when level in [:debug, :info, :busy, :success, :warn, :error] do
    GenStage.call(__MODULE__, {:remove_level_filter, level})
  end

  @doc false
  def start_link do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {:consumer, %{verbosity: @default_log_verbosity, level_filters: []}, subscribe_to: [Farmbot.Logger]}
  end

  def handle_events(events, _, %{verbosity: verbosity_filter, level_filters: filters} = state) do
    for log <- events do
      if log.verbosity <= verbosity_filter and log.level not in filters do
        maybe_log(log)
      end
    end
    {:noreply, [], state}
  end

  defp maybe_log(%Farmbot.Log{module: nil} = log) do
    IO.inspect log
    :ok
  end

  defp maybe_log(%Farmbot.Log{module: module} = log) do
    # should_log = List.first(Module.split(module)) == "Farmbot"
    # if should_log do
      IO.inspect log
    # else
      # :ok
    # end
  end

  def handle_call({:set_verbosity_level, num}, _from, state) do
    {:reply, :ok, [], %{state | verbosity: num}}
  end

  def handle_call({:filter_level, level}, _from, %{level_filters: filters} = state) do
    if level not in filters do
      {:reply, :ok, [], %{state | level_filters: [level | filters]}}
    else
      {:reply, :ok, [], state}
    end
  end

  def handle_call({:filter_level, _}, _, state) do
    {:reply, :ok, [], state}
  end

  def handle_call({:remove_level_filter, level}, _from, state) do
    {:reply, :ok, [], %{state | level_filters: List.delete(level, state.level_filters)}}
  end
end
