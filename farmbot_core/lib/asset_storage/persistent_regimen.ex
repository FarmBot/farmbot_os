defmodule Farmbot.Asset.PersistentRegimen do
  @moduledoc """
  A persistent regimen is a join between a started farm event and the regimen
  it is set to operate on. These are stored in the database to persist reboots,
  crashes etc.
  """

  alias Farmbot.Asset.PersistentRegimen
  use Ecto.Schema
  import Ecto.Changeset

  schema "persistent_regimens" do
    field :regimen_id, :integer
    field :farm_event_id, :integer
    field :time, :utc_datetime
    timestamps()
  end

  @required_fields [:regimen_id, :farm_event_id, :time]

  def changeset(%PersistentRegimen{} = pr, params \\ %{}) do
    pr
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:regimen_start_time, name: :regimen_start_time)
  end
end
