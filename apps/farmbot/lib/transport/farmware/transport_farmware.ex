alias Experimental.GenStage
defmodule Farmbot.Transport.Farmware do
  @moduledoc """
    Transport for exchanging celeryscript too Farmware packages.
  """
  use GenStage
  require Logger

  @doc """
    Starts the handler that watches the mqtt client
  """
  @spec start_link :: {:ok, pid}
  def start_link,
    do: GenStage.start_link(__MODULE__, [], name: __MODULE__)

  @spec init(any) :: {:consumer, any, subscribe_to: [Farmbot.Transport]}
  def init(initial) do
    {:consumer, initial, subscribe_to: [Farmbot.Transport]}
  end

  def handle_events(events, _, state) do
    for event <- events do
      Logger.info("#{__MODULE__}: Got event: #{inspect event}")
    end
    {:noreply, [], state}
  end

  def handle_info({_from, event}, state) do
    GenServer.cast(Farmware.Worker, event)
    {:noreply, [], state}
  end
end
