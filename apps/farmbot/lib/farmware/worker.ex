defmodule Farmware.Worker do
  @moduledoc """
    Takes scripts off the queue, and executes them?
  """

  require Logger
  use GenStage
  @tracker Farmware.Tracker
  alias Farmware.FarmScript

  @type env :: map

  @doc """
    Starts the Farmware Worker
  """
  @spec start_link :: {:ok, pid}
  def start_link, do: GenStage.start_link(__MODULE__, %{}, name: __MODULE__)

  @spec init(map) :: {:consumer, env, subscribe_to: [atom]}
  def init(_) do
    Logger.debug "Starting Farmware Worker"
    {:consumer, initial_env(), subscribe_to: [@tracker]}
  end

  @spec initial_env :: env
  defp initial_env do
    %{"WRITE_PATH" => "/tmp", "BEGIN_CS" => "<<< "}
  end

  # when a queue of scripts comes in execute them in order
  @lint false
  def handle_events(farm_scripts, _from, environment) do
    Logger.debug "#{__MODULE__} handling #{Enum.count(farm_scripts)} scripts"
    for scr <- farm_scripts do
      FarmScript.run(scr, get_env(environment))
    end
    Logger.debug "#{__MODULE__} done with farm_scripts"
    {:noreply, [], environment}
  end

  @lint false
  def handle_info(info, environment) do
    Logger.debug ">> got unhandled info in Farmware Worker: #{inspect info}", nopub: true
    {:noreply, [], environment}
  end

  @lint false
  def handle_cast({:status, status}, environment) do
    {:noreply, [], Map.put(environment, "STATUS", Poison.encode!(status))}
  end

  def handle_cast(_info, environment) do
    {:noreply, [], environment}
  end

  @spec get_env(env) :: [{binary, binary}]
  defp get_env(environment) do
    Enum.map(environment, fn({key, value}) ->
      {String.to_charlist(key), String.to_charlist(value)}
    end)
  end
end
