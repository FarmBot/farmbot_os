defmodule FarmbotCore.Asset.Tool do
  @moduledoc "A Tool is an item that lives in a ToolSlot"

  use FarmbotCore.Asset.Schema, path: "/api/tools"

  schema "tools" do
    field(:id, :id)

    has_one(:local_meta, FarmbotCore.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view tool do
    %{
      id: tool.id,
      name: tool.name
    }
  end

  def changeset(tool, params \\ %{}) do
    tool
    |> cast(params, [:id, :name, :monitor, :created_at, :updated_at])
    |> validate_required([])
  end
end
