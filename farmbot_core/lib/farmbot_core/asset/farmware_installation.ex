defmodule FarmbotCore.Asset.FarmwareInstallation do
  @moduledoc """
  """

  alias FarmbotCore.Asset.FarmwareInstallation.Manifest

  use FarmbotCore.Asset.Schema, path: "/api/farmware_installations"

  schema "farmware_installations" do
    field(:id, :id)

    has_one(:local_meta, FarmbotCore.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:url, :string)

    embeds_one(:manifest, Manifest, on_replace: :update)
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view farmware_installation do
    %{
      id: farmware_installation.id,
      url: farmware_installation.url
    }
  end

  def changeset(farmware_installation, params \\ %{}) do
    farmware_installation
    |> cast(params, [:id, :url, :monitor, :created_at, :updated_at])
    |> cast_embed(:manifest)
    |> validate_required([])
  end
end
