defmodule FarmbotCore.FarmEventWorker.SequenceEvent do
  require Logger
  require FarmbotCore.Logger
  alias FarmbotCeleryScript.AST
  alias FarmbotCore.{
    Asset,
    Asset.FarmEvent
  }
  use GenServer

  # Allow 'catchup' executions for ocurrences due in the past 15 minutes
  # This matches CeleryScript.Scheduler setting
  @grace_period_s 900

  @impl GenServer
  def init([farm_event, args]) do
    send self(), :schedule
    {:ok, %{farm_event: farm_event, args: args, timesync_waits: 0}}
  end

  @impl GenServer
  def handle_info(:schedule, state) do
    unless NervesTime.synchronized? do
      {:noreply, %{state | timesync_waits: state.timesync_waits + 1}, 3_000}
    else
      base_time = DateTime.add(DateTime.utc_now(), 0 - @grace_period_s)
      farm_event = state.farm_event

      farm_event
      |> FarmEvent.build_calendar(base_time)
      # get rid of any item that has already been scheduled/executed
      |> Enum.reject(fn(scheduled_at) ->
        Asset.get_farm_event_execution(farm_event, scheduled_at)
      end)
      |> Enum.each(fn(at) ->
        schedule_sequence(farm_event, at)
      end)
      {:noreply, state}
    end
  end

  def handle_info(:timeout, state) do
    Process.send_after(self(), :schedule, 1_000)
    {:noreply, state}
  end

  def handle_info({FarmbotCeleryScript, {:scheduled_execution, scheduled_at, executed_at, result}}, state) do
    status = case result do
      :ok -> "ok"
      {:error, reason} -> 
        FarmbotCore.Logger.error(2, "Event scheduled at #{scheduled_at} failed to execute: #{reason}")
        reason
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
    celery_args = 
      celery_ast.args
      |> Map.put(:sequence_name, sequence.name)
      |> Map.put(:locals, %{celery_ast.args.locals | body: celery_ast.args.locals.body ++ param_appls})
    
    celery_ast = %{celery_ast | args: celery_args}
    FarmbotCeleryScript.schedule(celery_ast, at, farm_event)
  end
end
