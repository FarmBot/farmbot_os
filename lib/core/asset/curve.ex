defmodule FarmbotOS.Asset.Curve do
  @moduledoc "A curve maps plant age in days to water or distance values."

  use FarmbotOS.Asset.Schema, path: "/api/curves"

  schema "curves" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
    field(:type, :string)
    field(:data, :map)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view curve do
    %{
      id: curve.id,
      name: curve.name,
      type: curve.type,
      data: curve.data
    }
  end

  def changeset(curve, params \\ %{}) do
    curve
    |> cast(params, [
      :id,
      :name,
      :type,
      :data,
      :monitor,
      :created_at,
      :updated_at
    ])
    |> validate_required([])
    |> unique_constraint(:id)
  end
end
