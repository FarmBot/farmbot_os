defmodule FarmbotCore.Asset.PublicKey do
  @moduledoc """
  Public keys can be used to SSH into a device for
  debug purposes
  """

  use FarmbotCore.Asset.Schema, path: "/api/public_keys"

  schema "public_keys" do
    field(:id, :id)

    has_one(:local_meta, FarmbotCore.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:name, :string)
    field(:public_key, :string)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view public_key do
    %{
      id: public_key.id,
      name: public_key.name,
      public_key: public_key.public_key
    }
  end

  def changeset(public_key, params \\ %{}) do
    public_key
    |> cast(params, [:id, :name, :public_key, :monitor, :created_at, :updated_at])
    |> validate_required([])
  end
end
