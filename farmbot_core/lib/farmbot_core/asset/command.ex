defmodule FarmbotCore.Asset.Command do
  @moduledoc """
  A collection of functions that _write_ to the DB
  """
  alias FarmbotCore.{Asset, Asset.Repo, Asset.Device}
  @type kind :: String.t()
  @type params :: map()
  @type id :: float()
  @type return_type :: :ok

  @callback update(kind, params, id) :: return_type
  def update("Device", params) do
    Asset.device() |> Device.changeset(params) |> Repo.update!()
  end

  def update("FbosConfig", params, _),
    do: Asset.update_fbos_config!(params)

  def update("FirmwareConfig", params, _),
    do: Asset.update_firmware_config!(params)

  def update("FarmwareEnv", params, id),
    do: Asset.upsert_farmware_env_by_id(id, params)

  def update("FarmwareInstallation", id, params),
    do: Asset.upsert_farmware_env_by_id(id, params)

  # Deletion use case:
  def update(asset_kind, nil, id) do
    old = Repo.get_by(as_module(asset_kind), id: id)
    old && Repo.delete!(old)
    :ok
  end

  # Catch-all use case:
  def update(asset_kind, params, id) do
    case Repo.get_by(as_module(asset_kind), id: id) do
      nil ->
        struct(asset_kind)
        |> asset_kind.changeset(params)
        |> Repo.insert!()

      asset ->
        asset_kind.changeset(asset, params)
        |> Repo.update!()
    end

    :ok
  end

  @callback new_cache_changeset(kind, params, id) :: return_type
  def new_cache_changeset(asset_kind, params, id) do
    mod = as_module(asset_kind)
    asset = Repo.get_by(mod, id: id) || struct(asset_kind)
    mod.changeset(asset, params)
  end

  # Convert string `"Device"` to module `Asset.Device`
  defp as_module(asset_kind) do
    Module.concat([Asset, asset_kind])
  end
end
