defmodule Farmware.Worker do
  @moduledoc """
    Takes scripts off the queue, and executes them?
  """

  require Logger
  use GenStage
  @tracker Farmware.Tracker
  alias Farmware.FarmScript
  alias Farmbot.Context

  @type env :: map

  @doc """
    Starts the Farmware Worker
  """
  def start_link(%Context{} = ctx, args),
    do: GenStage.start_link(__MODULE__, ctx, args)

  def init(context) do
    Logger.info "Starting Farmware Worker"
    {:consumer, %{env: initial_env(context), context: context}, subscribe_to: [@tracker]}
  end

  @doc """
    Gets the state
  """
  @spec get_state :: map
  def get_state, do: GenServer.call(__MODULE__, :get_state)

  @spec initial_env(Context.t) :: env
  defp initial_env(%Context{} = context) do
    %{"WRITE_PATH" => "/tmp", # common write path (non persistant)
      "BEGIN_CS" => "<<< ", # some in band signaling for executing celeryscript.
      "IMAGES" => "/tmp/images"} # Dump images here to upload them to the api
    |> Map.merge(Farmbot.BotState.get_config(context, :user_env))
  end

  # when a queue of scripts comes in execute them in order
  def handle_events(farm_scripts, _from, %{env: environment} = state) do
    Logger.info "Farmware Worker handling #{Enum.count(farm_scripts)} scripts"
    for scr <- farm_scripts do
      FarmScript.run(state.context, scr, get_env(environment))
    end
    Logger.info "Farmware Worker done with farm_scripts"
    {:noreply, [], state}
  end

  def handle_call({:add_envs, map}, _, state) do
    {:reply, :ok, [], Map.merge(state, map)}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, [], state}
  end

  # Discard leaking port info from farmwares
  def handle_info({port, _info}, s) when is_port(port), do: {:noreply, [], s}

  def handle_info(info, environment) do
    Logger.info ">> got unhandled info in " <>
      "Farmware Worker: #{inspect info}", nopub: true
    {:noreply, [], environment}
  end

  def handle_cast(_info, environment), do: {:noreply, [], environment}

  def add_envs(%Context{} = context, map) do
    GenServer.call(context.farmware_worker, {:add_envs, map})
  end

  @spec get_env(env) :: [{binary, binary}]
  defp get_env(environment) do
    Enum.map(environment, fn({key, value}) ->
      {String.to_charlist(key), String.to_charlist(value)}
    end)
  end
end
