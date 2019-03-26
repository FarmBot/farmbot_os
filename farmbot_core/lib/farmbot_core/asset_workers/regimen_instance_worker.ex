defimpl FarmbotCore.AssetWorker, for: FarmbotCore.Asset.RegimenInstance do
  @moduledoc """
  An instance of a running Regimen. Asset.Regimen is the blueprint by which a
  Regimen "instance" is created.
  """

  use GenServer
  require Logger
  require FarmbotCore.Logger

  alias FarmbotCore.Asset
  alias FarmbotCore.Asset.{RegimenInstance, FarmEvent, Regimen}
  alias FarmbotCeleryScript.{Scheduler, AST, Compiler}
  alias FarmbotCeleryScript.Scheduler

  @checkup_time_ms Application.get_env(:farmbot_core, __MODULE__)[:checkup_time_ms]
  @checkup_time_ms ||
    Mix.raise("""
    config :farmbot_core, #{__MODULE__}, checkup_time_ms: 10_000
    """)

  def preload(%RegimenInstance{}), do: [:farm_event, :regimen]

  def start_link(regimen_instance, args) do
    GenServer.start_link(__MODULE__, [regimen_instance, args])
  end

  def init([persistent_regimen, args]) do
    apply_sequence = Keyword.get(args, :apply_sequence, &apply_sequence/2)
    unless is_function(apply_sequence, 2) do
      raise "RegimenInstance Sequence handler should be a 2 arity function"
    end
    Process.put(:apply_sequence, apply_sequence)

    with %Regimen{} <- regimen_instance.regimen,
         %FarmEvent{} <- regimen_instance.farm_event do
      {:ok, filter_items(regimen_instance), 0}
    else
      _ -> {:stop, "Regimen instance not preloaded."}
    end
  end

  def handle_info(:timeout, %RegimenInstance{next: nil} = pr) do
    regimen_instance = filter_items(pr)
    calculate_next(regimen_instance, 0)
  end

  def handle_info(:timeout, %RegimenInstance{} = pr) do
    # Check if pr.next is around 2 minutes in the past
    # positive if the first date/time comes after the second.
    comp = Timex.diff(DateTime.utc_now(), pr.next, :minutes)

    cond do
      # now is more than 2 minutes past expected execution time
      comp > 2 ->
        Logger.warn(
          "Regimen: #{pr.regimen.name || "regimen"} too late: #{comp} minutes difference."
        )

        calculate_next(pr)

      true ->
        Logger.warn(
          "Regimen: #{pr.regimen.name || "regimen"} has not run before: #{comp} minutes difference."
        )

        exe = Asset.get_sequence!(id: pr.next_sequence_id)
        fun = Process.get(:apply_sequence)
        apply(fun, [exe, pr.regimen.body])
        calculate_next(pr)
    end
  end

  defp calculate_next(pr, checkup_time_ms \\ @checkup_time_ms)

  defp calculate_next(%{regimen: %{regimen_items: [next | rest]} = reg} = pr, checkup_time_ms) do
    next_dt = Timex.shift(pr.epoch, milliseconds: next.time_offset)
    params = %{next: next_dt, next_sequence_id: next.sequence_id}
    # TODO(Connor) - This causes the active GenServer to be
    #                Restarted due to the `AssetMonitor`
    pr = Asset.update_regimen_instance!(pr, params)

    pr = %{
      pr
      | regimen: %{reg | regimen_items: rest}
    }

    {:noreply, pr, checkup_time_ms}
  end

  defp calculate_next(%{regimen: %{regimen_items: []}} = pr, _) do
    FarmbotCore.Logger.success(1, "#{pr.regimen.name || "regimen"} has no more items.")
    {:noreply, pr, :hibernate}
  end

  defp filter_items(%RegimenInstance{regimen: %Regimen{} = reg} = pr) do
    items =
      reg.regimen_items
      |> Enum.sort(&(&1.time_offset <= &2.time_offset))

    %{pr | regimen: %{reg | regimen_items: items}}
  end

  # TODO(RickCarlino) This function essentially copy/pastes a regimen body into
  # the `locals` of a sequence, which works but is not-so-clean. Refactor later
  # when we have a better idea of the problem.
  defp apply_sequence(sequence, regimen_body) do
    param_appls = AST.decode(regimen_body)
    celery_ast =  AST.decode(sequence)

    celery_ast = %{
      celery_ast
      | args: %{
          celery_ast.args
          | locals: %{celery_ast.args.locals | body: celery_ast.args.locals.body ++ param_appls}
        }
    }

    compiled = compiled_celery = Compiler.compile(celery_ast)
    Scheduler.schedule(compiled)
  end
end
