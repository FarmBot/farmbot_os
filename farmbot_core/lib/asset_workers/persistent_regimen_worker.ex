defimpl Farmbot.AssetWorker, for: Farmbot.Asset.PersistentRegimen do
  use GenServer
  require Logger
  require Farmbot.Logger

  alias Farmbot.Asset
  alias Farmbot.Asset.{PersistentRegimen, FarmEvent, Regimen}
  alias Farmbot.Core.CeleryScript

  @checkup_time_ms Application.get_env(:farmbot_core, __MODULE__)[:checkup_time_ms]
  @checkup_time_ms ||
    Mix.raise("""
    config :farmbot_core, #{__MODULE__}, checkup_time_ms: 10_000
    """)

  def preload(%PersistentRegimen{}), do: [:farm_event, :regimen]

  def start_link(persistent_regimen) do
    GenServer.start_link(__MODULE__, [persistent_regimen])
  end

  def init([persistent_regimen]) do
    with %Regimen{} <- persistent_regimen.regimen,
         %FarmEvent{} <- persistent_regimen.farm_event do
      {:ok, filter_items(persistent_regimen), 0}
    else
      _ -> {:stop, "Persistent Regimen not preloaded."}
    end
  end

  def handle_info(:timeout, %PersistentRegimen{next: nil} = pr) do
    persistent_regimen = filter_items(pr)
    calculate_next(persistent_regimen, 0)
  end

  def handle_info(:timeout, %PersistentRegimen{} = pr) do
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
        CeleryScript.sequence(exe, fn _ -> :ok end)
        calculate_next(pr)
    end
  end

  defp calculate_next(pr, checkup_time_ms \\ @checkup_time_ms)

  defp calculate_next(%{regimen: %{regimen_items: [next | rest]} = reg} = pr, checkup_time_ms) do
    next_dt = Timex.shift(pr.epoch, milliseconds: next.time_offset)
    params = %{next: next_dt, next_sequence_id: next.sequence_id}
    # TODO(Connor) - This causes the active GenServer to be
    #                Restarted due to the `AssetMonitor`
    pr = Asset.update_persistent_regimen!(pr, params)

    pr = %{
      pr
      | regimen: %{reg | regimen_items: rest}
    }

    {:noreply, pr, checkup_time_ms}
  end

  defp calculate_next(%{regimen: %{regimen_items: []}} = pr, _) do
    Farmbot.Logger.success(1, "#{pr.regimen.name || "regimen"} has no more items.")
    {:noreply, pr, :hibernate}
  end

  defp filter_items(%PersistentRegimen{regimen: %Regimen{} = reg} = pr) do
    items =
      reg.regimen_items
      |> Enum.sort(&(&1.time_offset <= &2.time_offset))

    %{pr | regimen: %{reg | regimen_items: items}}
  end
end
