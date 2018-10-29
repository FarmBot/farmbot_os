defmodule Farmbot.Asset.PersistentRegimen do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:local_id, :binary_id, autogenerate: true}
  @timestamps_opts inserted_at: :created_at, type: :utc_datetime

  schema "persistent_regimens" do
    belongs_to(:regimen, Farmbot.Asset.Regimen, references: :local_id, type: :binary_id)
    belongs_to(:farm_event, Farmbot.Asset.FarmEvent, references: :local_id, type: :binary_id)
    field(:started_at, :utc_datetime)
    timestamps()
  end

  def changeset(persistent_regimen, params \\ %{}) do
    persistent_regimen
    |> cast(params, [:started_at])
    |> cast_assoc(:regimen)
    |> cast_assoc(:farm_event)
  end
end
