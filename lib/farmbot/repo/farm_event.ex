defmodule Farmbot.Repo.FarmEvent do
  @moduledoc """
  FarmEvent's are events that happen on a schedule.
  When it is time for the event to execute one of several things may happen:

      * A Regimen gets started.
      * A Sequence will execute.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "farm_events" do
    field :start_time,      :utc_datetime
    field :end_time,        :utc_datetime
    field :repeat,          :integer
    field :time_unit,       :string
    field :executable_type, Farmbot.Repo.ModuleType.FarmEvent
    field :executable_id,   :integer
  end

  use Farmbot.Repo.Syncable
  @required_fields [:id, :start_time, :end_time, :repeat,
                    :time_unit, :executable_type, :executable_id]

  def changeset(farm_event, params \\ %{}) do
    farm_event
    |> ensure_time([:start_time, :end_time])
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end

end
