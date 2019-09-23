defmodule FarmbotCore.Asset.PointGroup do
  @moduledoc """
  PointGroup is a list of points referenced by API id
  """

  use FarmbotCore.Asset.Schema, path: "/api/point_groups"

  schema "point_groups" do
    field(:id, :id)

    has_one(:local_meta, FarmbotCore.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
    field(:point_ids, {:array, :integer})

    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view point_group do
    %{
      id: point_group.id,
      name: point_group.name,
      point_ids: point_group.point_ids
    }
  end

  def changeset(point_group, params \\ %{}) do
    point_group
    |> cast(params, [:id, :name, :point_ids, :monitor, :created_at, :updated_at])
    |> validate_required([])
  end
end
