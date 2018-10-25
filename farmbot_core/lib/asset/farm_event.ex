defmodule Elixir.Farmbot.Asset.FarmEvent do
  @moduledoc """
  """

  use Farmbot.Asset.Schema, path: "/api/farm_events"

  schema "farm_events" do
    field(:id, :id)

    has_one(:local_meta, Farmbot.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:end_time, :utc_datetime)
    field(:executable_type, :string)
    field(:executable_id, :id)
    field(:repeat, :integer)
    field(:start_time, :utc_datetime)
    field(:time_unit, :string)

    # Private
    field(:last_executed, :utc_datetime)

    timestamps()
  end

  view farm_event do
    %{
      id: farm_event.id,
      end_time: farm_event.end_time,
      executable_type: farm_event.executable_type,
      executable_id: farm_event.executable_id,
      repeat: farm_event.repeat,
      start_time: farm_event.start_time,
      time_unit: farm_event.time_unit,
    }
  end

  def changeset(farm_event, params \\ %{}) do
    farm_event
    |> cast(params, [
      :id,
      :end_time,
      :executable_type,
      :executable_id,
      :repeat,
      :start_time,
      :time_unit,
      :last_executed,
      :created_at,
      :updated_at
    ])
    |> validate_required([])
  end

  @compile {:inline, [build_calendar: 2]}
  def build_calendar(%__MODULE__{executable_type: "Regimen"} = fe, _), do: fe.start_time

  def build_calendar(%__MODULE__{time_unit: "never"} = fe, _), do: fe.start_time

  def build_calendar(%__MODULE__{} = fe, current_date_time) do
    current_time_seconds = DateTime.to_unix(current_date_time)
    start_time_seconds = DateTime.to_unix(fe.start_time, :second)
    end_time_seconds = DateTime.to_unix(fe.end_time, :second)

    repeat = fe.repeat
    repeat_frequency_seconds = time_unit_to_seconds(fe.time_unit)

    do_build_calendar(
      current_time_seconds,
      start_time_seconds,
      end_time_seconds,
      repeat,
      repeat_frequency_seconds
    ) |> DateTime.from_unix!()
  end

  def do_build_calendar(_,_,_,_,_), do: :erlang.nif_error("NIF Not loaded")

  @on_load :load_nif
  def load_nif do
    require Logger
    nif_file = '#{:code.priv_dir(:farmbot_core)}/build_calendar'

    case :erlang.load_nif(nif_file, 0) do
      :ok -> :ok
      {:error, {:reload, _}} -> :ok
      {:error, reason} -> Logger.warn("Failed to load nif: #{inspect(reason)}")
    end
  end

  @compile {:inline, [time_unit_to_seconds: 1]}
  defp time_unit_to_seconds("minutely"), do: 60
  defp time_unit_to_seconds("hourly"), do: 60 * 60
  defp time_unit_to_seconds("daily"), do: 60 * 60 * 24
  defp time_unit_to_seconds("weekly"), do: 60 * 60 * 24 * 7
  defp time_unit_to_seconds("monthly"), do: 60 * 60 * 24 * 30
  defp time_unit_to_seconds("yearly"), do: 60 * 60 * 24 * 365
end
