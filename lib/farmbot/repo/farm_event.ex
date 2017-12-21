defmodule Farmbot.Repo.FarmEvent do
  @moduledoc """
  FarmEvent's are events that happen on a schedule.
  When it is time for the event to execute one of several things may happen:

      * A Regimen gets started.
      * A Sequence will execute.
  """

  alias Farmbot.Repo.JSONType

  use Ecto.Schema
  import Ecto.Changeset

  schema "farm_events" do
    field(:start_time, :string)
    field(:end_time, :string)
    field(:repeat, :integer)
    field(:time_unit, :string)
    field(:executable_type, Farmbot.Repo.ModuleType.FarmEvent)
    field(:executable_id, :integer)
    field(:calendar, JSONType)
  end

  use Farmbot.Repo.Syncable

  @required_fields [
    :id,
    :start_time,
    :end_time,
    :repeat,
    :time_unit,
    :executable_type,
    :executable_id
  ]

  def changeset(farm_event, params \\ %{}) do
    farm_event
    |> build_calendar
    |> cast(params, @required_fields ++ [:calendar])
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end

  def build_calendar(%__MODULE__{calendar: nil} = fe), do: fe
  def build_calendar(%__MODULE__{calendar: calendar} = fe)  when is_list(calendar) do
    # Date Time objects.
    current_time_dt = Timex.now()
    {:ok, start_time_dt, _} = DateTime.from_iso8601(fe.start_time)
    {:ok, end_time_dt,   _} = DateTime.from_iso8601(fe.end_time)

    # Unix timestamps from those objects.
    current_time_unix = DateTime.to_unix(current_time_dt)
    start_time_unix = DateTime.to_unix(start_time_dt)
    end_time_unix = DateTime.to_unix(end_time_dt)

    interval_seconds = time_unit_to_seconds(fe.repeat, fe.time_unit)
    grace_period_cutoff_dt = Timex.subtract(current_time_dt, Timex.Duration.from_minutes(1))

    new_calendar = Range.new(start_time_unix, end_time_unix)
    |> Enum.take_every(fe.repeat * interval_seconds)
    |> Enum.map(&DateTime.from_unix!(&1))
    |> Enum.filter(&Timex.after?(&1, grace_period_cutoff_dt))
    |> Enum.map(&(Timex.shift(&1, seconds: -(&1.second), microseconds: -(&1.microsecond |> elem(0)))))
    |> Enum.map(&DateTime.to_iso8601(&1))
    |> Enum.take(60)
    %{fe | calendar: new_calendar}
  end

  defp time_unit_to_seconds(_, "never"), do: 0
  defp time_unit_to_seconds(repeat, "minutely"), do: 60 * repeat
  defp time_unit_to_seconds(repeat, "hourly"), do: 60 * 60 * repeat
  defp time_unit_to_seconds(repeat, "daily"), do: 60 * 60 * 24 * repeat
  defp time_unit_to_seconds(repeat, "weekly"), do: 60 * 60 * 24 * 7 * repeat
  defp time_unit_to_seconds(repeat, "monthly"), do: 60 * 60 * 24 * 30 * repeat
  defp time_unit_to_seconds(repeat, "yearly"), do: 60 * 60 * 24 * 365 * repeat
end
