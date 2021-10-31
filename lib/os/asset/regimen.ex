defmodule FarmbotOS.Asset.Regimen do
  @moduledoc """
  A Regimen is a schedule to run sequences on.
  """

  use FarmbotOS.Asset.Schema, path: "/api/regimens"
  alias FarmbotOS.Asset.Regimen.{Item, BodyNode}

  schema "regimens" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
    embeds_many(:regimen_items, Item, on_replace: :delete)
    embeds_many(:body, BodyNode, on_replace: :delete)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view regimen do
    %{
      id: regimen.id,
      name: regimen.name,
      regimen_items: Enum.map(regimen.regimen_items, &Item.render(&1)),
      body: Enum.map(regimen.body, &BodyNode.render(&1))
    }
  end

  def changeset(regimen, params \\ %{}) do
    regimen
    |> cast(params, [:id, :name, :monitor, :created_at, :updated_at])
    |> cast_embed(:regimen_items)
    |> cast_embed(:body)
    |> validate_required([])
  end
end
