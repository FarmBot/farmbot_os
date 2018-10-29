defmodule Farmbot.Asset.Tool do
  @moduledoc "A Tool is an item that lives in a ToolSlot"

  use Farmbot.Asset.Schema, path: "/api/tools"

  schema "tools" do
    field(:id, :id)

    has_one(:local_meta, Farmbot.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
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
    |> cast(params, [:id, :name, :created_at, :updated_at])
    |> validate_required([])
  end
end
