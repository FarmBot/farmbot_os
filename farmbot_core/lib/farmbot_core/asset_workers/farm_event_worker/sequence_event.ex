defmodule FarmbotCore.FarmEventWorker.SequenceEvent do
  require Logger
  alias FarmbotCeleryScript.AST
  alias FarmbotCore.{
    Asset,
    Asset.FarmEvent
  }
  use GenServer

  @impl GenServer
  def init([farm_event, args]) do
    send self(), :schedule
    {:ok, %{farm_event: farm_event, args: args}}
  end

  @impl GenServer
  def handle_info(:schedule, state) do
    farm_event = state.farm_event

    farm_event
    |> FarmEvent.build_calendar(DateTime.utc_now())
    # get rid of any item that has already been scheduled/executed
    |> Enum.reject(fn(scheduled_at) ->
      Asset.get_farm_event_execution(farm_event, scheduled_at)
    end)
    |> Enum.each(fn(at) ->
      schedule_sequence(farm_event, at)
    end)
    {:noreply, state}
  end

  def handle_info({FarmbotCeleryScript, {:scheduled_execution, scheduled_at, executed_at, result}}, state) do
    status = case result do
      :ok -> "ok"
      {:error, reason} -> reason
    end
    _ = Asset.add_execution_to_farm_event!(state.farm_event, %{
      scheduled_at: scheduled_at,
      executed_at: executed_at,
      status: status
    })
    {:noreply, state}
  end

  def schedule_sequence(farm_event, at) do
    sequence = Asset.get_sequence(farm_event.executable_id)
    sequence || raise("Sequence #{farm_event.executable_id} is not synced")
    param_appls = AST.decode(farm_event.body)
    celery_ast =  AST.decode(sequence)
    celery_ast = %{
      celery_ast
      | args: %{
          celery_ast.args
          | locals: %{celery_ast.args.locals | body: celery_ast.args.locals.body ++ param_appls}
        }
    }
    FarmbotCeleryScript.schedule(celery_ast, at, farm_event)
  end
end
