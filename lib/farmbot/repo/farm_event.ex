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
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end

  def build_calendar(%__MODULE__{calendar: nil} = fe), do: fe
  def build_calendar(%__MODULE__{calendar: calendar} = fe)  when is_list(calendar) do
    origin_time = Timex.now()
    interval_seconds = time_unit_to_seconds(fe.repeat, fe.time_unit)
    {:ok, lower_bound, _} = DateTime.from_iso8601(fe.start_time)
    {:ok, upper_bound, _} = DateTime.from_iso8601(fe.end_time)
    # Math.ceil((lowerBound.unix() - originTime.unix()) / intervalSeconds);
    skip_intervals = :math.ceil((DateTime.to_unix(lower_bound) - DateTime.to_unix(origin_time)) / interval_seconds)
    first_item = Timex.add(origin_time, Timex.Duration.from_seconds(interval_seconds * skip_intervals))
    list = [first_item]
    all_events = Enum.reduce(0..60, list, fn(_, acc) ->
      x = List.last(acc)
      if x do
        # const item = x.clone().add(intervalSeconds, "seconds");
        # if (item.isBefore(upperBound)) {
        #   list.push(item);
        # }
        item = Timex.add(x, Timex.Duration.from_seconds(interval_seconds))
        if Timex.before?(item, upper_bound) do
          acc ++ [item]
        else
          acc
        end
      else
        acc
      end
    end)
    |> Enum.map(&DateTime.to_iso8601(&1))
    %{fe | calendar: all_events}
  end

  defp time_unit_to_seconds(_, "never"), do: 0
  defp time_unit_to_seconds(repeat, "minutely"), do: 60 * repeat
  defp time_unit_to_seconds(repeat, "hourly"), do: 60 * 60 * repeat
  defp time_unit_to_seconds(repeat, "daily"), do: 60 * 60 * 24 * repeat
  defp time_unit_to_seconds(repeat, "weekly"), do: 60 * 60 * 24 * 7 * repeat
  defp time_unit_to_seconds(repeat, "monthly"), do: 60 * 60 * 24 * 30 * repeat
  defp time_unit_to_seconds(repeat, "yearly"), do: 60 * 60 * 24 * 365 * repeat
end
