defmodule FarmbotOS.Asset.PointGroup do
  @moduledoc """
  PointGroup is a list of points referenced by API id
  """

  use FarmbotOS.Asset.Schema, path: "/api/point_groups"

  @default_criteria %{
    "day" => %{"op" => ">", "days_ago" => 0},
    # Map<string, string[] | undefined>,
    "string_eq" => %{},
    # Map<string, number[] | undefined>,
    "number_eq" => %{},
    # Map<string, number | undefined>,
    "number_lt" => %{},
    # Map<string, number | undefined>,
    "number_gt" => %{}
  }

  schema "point_groups" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
    field(:point_ids, {:array, :integer})
    field(:sort_type, :string)
    field(:criteria, :map, default: @default_criteria)

    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view point_group do
    %{
      id: point_group.id,
      name: point_group.name,
      point_ids: point_group.point_ids,
      sort_type: point_group.sort_type,
      criteria: point_group.criteria
    }
  end

  def changeset(point_group, params \\ %{}) do
    point_group
    |> cast(params, [
      :id,
      :name,
      :criteria,
      :point_ids,
      :sort_type,
      :monitor,
      :created_at,
      :updated_at
    ])
    |> validate_required([])
  end
end
