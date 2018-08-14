defmodule Farmbot.Asset.Point do
  @moduledoc "A Point is a location in the planting bed as denoted by X Y and Z."

  alias Farmbot.Asset.Point
  use Ecto.Schema
  import Ecto.Changeset
  alias Farmbot.EctoTypes.ModuleType
  alias Farmbot.EctoTypes.TermType

  schema "points" do
    field(:name, :string)
    field(:tool_id, :integer)
    field(:x, :float)
    field(:y, :float)
    field(:z, :float)
    field(:meta, TermType)
    field(:pointer_type, ModuleType.Point)
  end

  @required_fields [:id, :name, :x, :y, :z, :meta, :pointer_type]
  @optional_fields [:tool_id]

  def changeset(%Point{} = point, params \\ %{}) do
    point
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
