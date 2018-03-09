defmodule Farmbot.Asset.Point do
  @moduledoc "A Point is a location in the planting bed as denoted by X Y and Z."

  use Ecto.Schema
  import Ecto.Changeset

  schema "points" do
    field(:name, :string)
    field(:tool_id, :integer)
    field(:x, Farmbot.Repo.JSONFloatType)
    field(:y, Farmbot.Repo.JSONFloatType)
    field(:z, Farmbot.Repo.JSONFloatType)
    field(:meta, Farmbot.Repo.JSONType)
    field(:pointer_type, Farmbot.Repo.ModuleType.Point)
  end

  use Farmbot.Repo.Syncable
  @required_fields [:id, :name, :x, :y, :z, :meta, :pointer_type]
  @optional_fields [:tool_id]

  def changeset(point, params \\ %{}) do
    point
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
