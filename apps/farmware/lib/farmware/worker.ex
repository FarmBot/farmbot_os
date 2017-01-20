alias Experimental.GenStage
defmodule Farmware.Worker do
  @moduledoc """
    Takes scripts off the queue, and executes them?
  """

  require Logger
  use GenStage
  @tracker Farmware.Tracker
  alias Farmware.FarmScript

  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.debug "Starting Farmware Worker"
    {:consumer, [], subscribe_to: [@tracker]}
  end

  # when a queue of scripts comes in execute them in order
  def handle_events(farm_scripts, _from, state) do
    Logger.debug "#{__MODULE__} handling #{Enum.count(farm_scripts)} scripts"
    for scr <- farm_scripts do
      FarmScript.run(scr)
    end
    Logger.debug "#{__MODULE__} done with farm_scripts"
    {:noreply, [], state}
  end

  def handle_info(info, state) do
    Logger.debug ">> got unhandled info in Farmware Worker: #{inspect info}"
    {:noreply, [], state}
  end

end
