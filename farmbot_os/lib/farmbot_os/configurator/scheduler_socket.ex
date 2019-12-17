defmodule FarmbotOS.Configurator.SchedulerSocket do
  @moduledoc """
  WebSocket handler responsible for dispatching information about
  currently scheduled celery_script tasks
  """

  require Logger
  alias FarmbotCore.{Asset, Asset.FarmEvent, Asset.Sequence}
  alias FarmbotCeleryScript.Scheduler

  @behaviour :cowboy_websocket

  @impl :cowboy_websocket
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  @impl :cowboy_websocket
  def websocket_init(_state) do
    send(self(), :after_connect)
    Scheduler.register()
    {:ok, %{}}
  end

  @impl :cowboy_websocket
  def websocket_handle({:text, message}, state) do
    case Jason.decode(message) do
      {:ok, json} ->
        websocket_handle({:json, json}, state)

      _ ->
        _ = Logger.debug("discarding info: #{message}")
        {:ok, state}
    end
  end

  @impl :cowboy_websocket
  def websocket_info({FarmbotCeleryScript, {:calendar, calendar}}, state) do
    data =
      Enum.map(calendar, fn
        %Scheduler.Dispatch{data: %FarmEvent{} = farm_event, scheduled_at: datetime} ->
          json =
            Jason.encode!(%{
              id: farm_event.local_id,
              type: "FarmEvent",
              data: Sequence.render(Asset.get_sequence(farm_event.executable_id)),
              at: datetime
            })

          {:text, json}

        %Scheduler.Dispatch{data: %Sequence{} = sequence, scheduled_at: datetime} ->
          json =
            Jason.encode!(%{
              id: sequence.local_id,
              type: "Sequence",
              data: Sequence.render(sequence),
              at: datetime
            })

          {:text, json}
      end)

    {:reply, data, state}
  end

  def websocket_info(info, state) do
    Logger.info("Dropping #{inspect(info)}")
    {:ok, state}
  end

  @impl :cowboy_websocket
  def terminate(_reason, _req, _state) do
    :ok
  end
end
