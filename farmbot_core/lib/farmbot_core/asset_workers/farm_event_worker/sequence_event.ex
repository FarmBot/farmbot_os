defmodule FarmbotCore.FarmEventWorker.SequenceEvent do
  alias FarmbotCeleryScript.AST
  alias FarmbotCore.{Asset, Asset.FarmEvent}
  use GenServer

  @impl GenServer
  def init([event, args]) do
    send self(), :checkup
    {:ok, %{event: event, args: args}}
  end

  @impl GenServer
  def handle_info(:checkup, state) do
    next_dt = FarmEvent.build_calendar(state.event, DateTime.utc_now())
    :ok = schedule(state.event, next_dt)
    {:noreply, state, state.args[:checkup_time_ms] || 15_000}
  end

  defp schedule(farm_event, at) do
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
    IO.inspect(celery_ast)
    IO.inspect(at)
    # FarmbotCeleryScript.schedule(celery_ast, at)
  end
end