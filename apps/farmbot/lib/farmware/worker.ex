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

  @doc """
    Gets the state
  """
  @spec get_state :: map
  def get_state, do: GenServer.call(__MODULE__, :get_state)

  @spec initial_env :: env
  defp initial_env do
    %{"WRITE_PATH" => "/tmp", # common write path (non persistant)
      "BEGIN_CS" => "<<< ", # some in band signaling for executing celeryscript.
      "IMAGES" => "/tmp/images"} # Dump images here to upload them to the api
    |> Map.merge(Farmbot.BotState.get_config(:user_env))
  end

  # when a queue of scripts comes in execute them in order
  def handle_events(farm_scripts, _from, environment) do
    Logger.debug "Farmware Worker handling #{Enum.count(farm_scripts)} scripts"
    for scr <- farm_scripts do
      # give ten seconds to accept a connection.
      #TODO(Connor) this will cause problems im sure.
      FarmScript.run(scr, get_env(environment))
    end
    Logger.debug "Farmware Worker done with farm_scripts"
    {:noreply, [], environment}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, [], state}
  end

  # Discard leaking port info from farmwares
  def handle_info({port, _info}, s) when is_port(port), do: {:noreply, [], s}

  def handle_info(info, environment) do
    Logger.debug ">> got unhandled info in " <>
      "Farmware Worker: #{inspect info}", nopub: true
    {:noreply, [], environment}
  end

  def handle_cast(_info, environment), do: {:noreply, [], environment}

  @spec get_env(env) :: [{binary, binary}]
  defp get_env(environment) do
    Enum.map(environment, fn({key, value}) ->
      {String.to_charlist(key), String.to_charlist(value)}
    end)
  end
end
