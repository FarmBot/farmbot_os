defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.RegimenInstance do
  @moduledoc """
  An instance of a running Regimen. Asset.Regimen is the blueprint by which a
  Regimen "instance" is created.
  """

  use GenServer
  require Logger
  require FarmbotCore.Logger

  alias FarmbotCeleryScript.AST
  alias FarmbotCore.Asset
  alias FarmbotCore.Asset.{RegimenInstance, FarmEvent, Sequence, Regimen}

  @impl FarmbotCore.AssetWorker
  def preload(%RegimenInstance{}), do: [:farm_event, :regimen, :executions]

  @impl FarmbotCore.AssetWorker
  def tracks_changes?(%RegimenInstance{}), do: false

  @impl FarmbotCore.AssetWorker
  def start_link(regimen_instance, args) do
    GenServer.start_link(__MODULE__, [regimen_instance, args])
  end

  @impl GenServer
  def init([regimen_instance, _args]) do
    Logger.warn "RegimenInstance #{inspect(regimen_instance)} initializing"

    with %Regimen{} <- regimen_instance.regimen,
         %FarmEvent{} <- regimen_instance.farm_event do
          send self(), :schedule
      {:ok, %{regimen_instance: regimen_instance}}
    else
      _ -> {:stop, "Regimen instance not preloaded."}
    end
  end

  @impl GenServer
  def handle_info(:schedule, state) do
    regimen_instance = state.regimen_instance
    # load the sequence and calculate the scheduled_at time
    Enum.map(regimen_instance.regimen.regimen_items, fn(%{time_offset: offset, sequence_id: sequence_id}) -> 
      scheduled_at = DateTime.add(regimen_instance.epoch, offset, :millisecond)
      sequence = Asset.get_sequence(sequence_id) || raise("sequence #{sequence_id} is not synced")
      %{scheduled_at: scheduled_at, sequence: sequence}
    end)
    # get rid of any item that has already been scheduled/executed
    |> Enum.reject(fn(%{scheduled_at: scheduled_at}) -> 
      Asset.get_regimen_instance_execution(regimen_instance, scheduled_at)
    end)
    |> Enum.each(fn(%{scheduled_at: at, sequence: sequence}) -> 
      schedule_sequence(regimen_instance, sequence, at)
    end)
    {:noreply, state}    
  end

  def handle_info({FarmbotCeleryScript, {:scheduled_execution, scheduled_at, executed_at, result}}, state) do
    status = case result do
      :ok -> "ok"
      {:error, reason} -> reason
    end
    _ = Asset.add_execution_to_regimen_instance!(state.regimen_instance, %{
      scheduled_at: scheduled_at,
      executed_at: executed_at,
      status: status
    })
    {:noreply, state}
  end

  # TODO(RickCarlino) This function essentially copy/pastes a regimen body into
  # the `locals` of a sequence, which works but is not-so-clean. Refactor later
  # when we have a better idea of the problem.
  @doc false
  def schedule_sequence(%RegimenInstance{} = regimen_instance, %Sequence{} = sequence, at) do
    # FarmEvent is the furthest outside of the scope
    farm_event_params = AST.decode(regimen_instance.farm_event.body)
    # Regimen is the second scope
    regimen_params = AST.decode(regimen_instance.regimen.body)
    # there may be many sequence scopes from here downward
    celery_ast =  AST.decode(sequence)

    celery_ast = %{
      celery_ast
      | args: %{
          celery_ast.args
          | locals: %{
            celery_ast.args.locals | body: celery_ast.args.locals.body ++ regimen_params ++ farm_event_params}
        }
    }
    FarmbotCeleryScript.schedule(celery_ast, at, sequence)
  end
end
