defmodule FarmbotOS.Asset.FarmEvent do
  use FarmbotOS.Asset.Schema, path: "/api/farm_events"

  alias FarmbotOS.Asset.FarmEvent.{
    BodyNode,
    Execution,
    Calendar
  }

  schema "farm_events" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    has_many(:executions, Execution,
      on_delete: :delete_all,
      on_replace: :delete
    )

    field(:end_time, :utc_datetime_usec)
    field(:executable_type, :string)
    field(:executable_id, :id)
    field(:repeat, :integer)
    field(:start_time, :utc_datetime_usec)
    field(:time_unit, :string)
    embeds_many(:body, BodyNode, on_replace: :delete)

    # Private
    field(:last_executed, :utc_datetime_usec)
    field(:monitor, :boolean, default: true)

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
      body: Enum.map(farm_event.body, &BodyNode.render/1)
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
      :monitor,
      :created_at,
      :updated_at
    ])
    |> cast_embed(:body)
    |> validate_required([])
  end

  def build_calendar(%__MODULE__{executable_type: "Regimen"} = fe, _),
    do: [fe.start_time]

  def build_calendar(%__MODULE__{time_unit: "never"} = fe, _),
    do: [fe.start_time]

  def build_calendar(%__MODULE__{} = fe, current_date_time) do
    current_time_seconds = DateTime.to_unix(current_date_time)
    start_time_seconds = DateTime.to_unix(fe.start_time, :second)
    end_time_seconds = DateTime.to_unix(fe.end_time, :second)

    repeat = fe.repeat
    repeat_frequency_seconds = time_unit_to_seconds(fe.time_unit)

    Calendar.new(
      current_time_seconds,
      end_time_seconds,
      repeat,
      repeat_frequency_seconds,
      start_time_seconds
    )
    |> Enum.map(&DateTime.from_unix!/1)
  end

  defp time_unit_to_seconds("minutely"), do: 60
  defp time_unit_to_seconds("hourly"), do: 60 * 60
  defp time_unit_to_seconds("daily"), do: 60 * 60 * 24
  defp time_unit_to_seconds("weekly"), do: 60 * 60 * 24 * 7
  defp time_unit_to_seconds("monthly"), do: 60 * 60 * 24 * 30
  defp time_unit_to_seconds("yearly"), do: 60 * 60 * 24 * 365
end
