defmodule Farmbot.Repo.Point do
  @moduledoc "A Point is a location in the planting bed as denoted by X Y and Z."

  use Ecto.Schema
  import Ecto.Changeset

  schema "points" do
    field :name, :string
    field :x, :float
    field :y, :float
    field :z, :float
    field :meta, Farmbot.Repo.JSONType
    field :pointer_type, Farmbot.Repo.Point.PointerType
    field :pointer_id, :integer
  end

  use Farmbot.Repo.Syncable
  @required_fields [:id, :name, :x, :y, :z, :meta, :pointer_type, :pointer_id]

  def changeset(farm_event, params \\ %{}) do
    farm_event
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end
end
