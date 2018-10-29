defmodule Elixir.Farmbot.Asset.FarmwareEnv do
  @moduledoc """
  """

  use Farmbot.Asset.Schema, path: "/api/farmware_envs"

  schema "farmware_envs" do
    field(:id, :id)

    has_one(:local_meta, Farmbot.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:key, :string)
    field(:value, :string)
    timestamps()
  end

  view farmware_env do
    %{
      id: farmware_env.id,
      key: farmware_env.key,
      value: farmware_env.value
    }
  end

  def changeset(farmware_env, params \\ %{}) do
    farmware_env
    |> cast(params, [:id, :key, :value, :created_at, :updated_at])
    |> validate_required([])
  end
end
