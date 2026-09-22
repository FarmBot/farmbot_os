defmodule FarmbotOS.Asset.Tool do
  @moduledoc "A Tool is an item that lives in a ToolSlot"

  use FarmbotOS.Asset.Schema, path: "/api/tools"

  schema "tools" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
    field(:type, :string)
    field(:utm_mountable, :boolean)
    field(:flow_rate_ml_per_s, :integer)
    field(:seeder_tip_z_offset, :float)
    field(:effector_offset_x, :float)
    field(:effector_offset_y, :float)
    field(:effector_offset_z, :float)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view tool do
    %{
      id: tool.id,
      name: tool.name,
      type: tool.type,
      utm_mountable: tool.utm_mountable,
      seeder_tip_z_offset: tool.seeder_tip_z_offset,
      effector_offset_x: tool.effector_offset_x,
      effector_offset_y: tool.effector_offset_y,
      effector_offset_z: tool.effector_offset_z,
      flow_rate_ml_per_s: tool.flow_rate_ml_per_s
    }
  end

  def changeset(tool, params \\ %{}) do
    tool
    |> cast(params, [
      :id,
      :name,
      :type,
      :utm_mountable,
      :flow_rate_ml_per_s,
      :seeder_tip_z_offset,
      :effector_offset_x,
      :effector_offset_y,
      :effector_offset_z,
      :monitor,
      :created_at,
      :updated_at
    ])
    |> validate_required([])
  end
end
