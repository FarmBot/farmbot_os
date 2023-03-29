defmodule FarmbotOS.Asset.Point do
  @moduledoc """
  Points are data around an x,y,z
  """
  use FarmbotOS.Asset.Schema, path: "/api/points"

  schema "points" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:discarded_at, :utc_datetime_usec)
    field(:gantry_mounted, :boolean)
    field(:meta, :map)
    field(:monitor, :boolean, default: true)
    field(:name, :string)
    field(:openfarm_slug, :string)
    field(:plant_stage, :string)
    field(:depth, :integer)
    field(:planted_at, :utc_datetime_usec)
    field(:water_curve_id, :integer)
    field(:spread_curve_id, :integer)
    field(:height_curve_id, :integer)
    field(:pointer_type, :string)
    field(:pullout_direction, :integer)
    field(:radius, :float)
    field(:tool_id, :integer)
    field(:x, :float)
    field(:y, :float)
    field(:z, :float)
    timestamps()
  end

  view point do
    %{
      id: point.id,
      meta: point.meta,
      name: point.name,
      plant_stage: point.plant_stage,
      depth: point.depth,
      created_at: point.created_at,
      updated_at: point.updated_at,
      planted_at: point.planted_at,
      water_curve_id: point.water_curve_id,
      spread_curve_id: point.spread_curve_id,
      height_curve_id: point.height_curve_id,
      pointer_type: point.pointer_type,
      radius: point.radius,
      tool_id: point.tool_id,
      discarded_at: point.discarded_at,
      gantry_mounted: point.gantry_mounted,
      openfarm_slug: point.openfarm_slug,
      pullout_direction: point.pullout_direction,
      x: point.x,
      y: point.y,
      z: point.z
    }
  end

  def changeset(point, params \\ %{}) do
    point
    |> cast(params, [
      :created_at,
      :discarded_at,
      :gantry_mounted,
      :id,
      :meta,
      :monitor,
      :name,
      :plant_stage,
      :depth,
      :planted_at,
      :water_curve_id,
      :spread_curve_id,
      :height_curve_id,
      :pointer_type,
      :pullout_direction,
      :openfarm_slug,
      :radius,
      :tool_id,
      :updated_at,
      :x,
      :y,
      :z
    ])
    |> validate_required([])
  end
end
