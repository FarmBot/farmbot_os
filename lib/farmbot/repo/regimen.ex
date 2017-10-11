defmodule Farmbot.Repo.Regimen do
  @moduledoc """
  A Regimen is a schedule to run sequences on.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "regimens" do
    field(:name, :string)
  end

  use Farmbot.Repo.Syncable
  @required_fields [:id, :name]

  def changeset(farm_event, params \\ %{}) do
    farm_event
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
