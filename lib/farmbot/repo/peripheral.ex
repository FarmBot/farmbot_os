defmodule Farmbot.Repo.Peripheral do
  @moduledoc """
  Peripherals are descriptors for pins/modes.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "peripherals" do
    add :pin, :integer
    add :mode, :integer
    add :label, :string
    add :created_at, :utc_datetime
    add :updated_at, :utc_datetime
  end

  use Farmbot.Repo.Syncable
  @required_fields [:id, :pin, :mode, :label, :created_at, :updated_at]

  def changeset(peripheral, params \\ %{}) do
    peripheral
    |> ensure_time([:created_at, :created_at])
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
