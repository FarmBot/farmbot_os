defmodule Elixir.Farmbot.Asset.FarmwareInstallation do
  @moduledoc """
  """

  use Farmbot.Asset.Schema, path: "/api/farmware_installations"

  schema "farmware_installations" do
    field(:id, :id)

    has_one(:local_meta, Farmbot.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:url, :string)
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
    |> cast(params, [:id, :url, :created_at, :updated_at])
    |> validate_required([])
  end
end
