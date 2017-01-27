defmodule Farmbot.Transport.Farmware do
  @moduledoc """
    Transport for exchanging celeryscript too Farmware packages.
  """
  use GenStage
  require Logger

  # GENSTAGE HACK
  @spec handle_call(any, any, any) :: {:reply, any, any}
  @spec handle_cast(any, any) :: {:noreply, any}
  @spec handle_info(any, any) :: {:noreply, any}
  @spec init(any) :: {:ok, any}
  @spec handle_events(any, any, any) :: no_return

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
