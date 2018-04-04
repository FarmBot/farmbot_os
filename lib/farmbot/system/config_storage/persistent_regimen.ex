defmodule Farmbot.System.ConfigStorage.PersistentRegimen do
  use Ecto.Schema
  import Ecto.Changeset
  alias Farmbot.System.ConfigStorage.PersistentRegimen

  schema "persistent_regimens" do
    field :regimen_id, :integer
    field :time, :utc_datetime
  end

  @required_fields [:regimen_id]

  def changeset(%PersistentRegimen{} = pr, params \\ %{}) do
    pr
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:regimen_id)
  end
end
