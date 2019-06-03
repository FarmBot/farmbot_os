defmodule FarmbotCore.Asset.Command do
  @moduledoc """
  A collection of functions that _write_ to the DB
  """
  require Logger

  alias FarmbotCore.{
    Asset,
    Asset.Repo,
    Asset.Device,
    Asset.FbosConfig
  }

  @type kind :: Device | FbosConfig | FwConfig | FarmwareEnv
  @type params :: map()
  @type id :: float()
  @type return_type :: Device.t() | FbosConfig.t() | FwConfig.t()

  # NOTE TO SELF:
  # "Alert"
  # "Device"
  # "FarmEvent"
  # "FarmwareEnv"
  # "FarmwareInstallation"
  # "FbosConfig"
  # "FirmwareConfig"
  # "Point"
  # "GlobalConfig"
  # "Image"
  # "Log"
  # "Peripheral"
  # "PinBinding"
  # "Point"
  # "PlantTemplate"
  # "Point"
  # "Regimen"
  # "RegimenItem"
  # "SavedGarden"
  # "Sensor"
  # "SensorReading"
  # "Sequence"
  # "TokenIssuance"
  # "Tool"
  # "Point"
  # "User"
  # "WebAppConfig"
  # "WebcamFeed"

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

  # Deleteion use case:
  def update(asset_kind, nil, id) do
    old = Repo.get_by(asset_kind, id: id)
    old && Repo.delete!(old)
    :ok
  end

  # Catach-all usee case:
  def update(asset_kind, params, id) do
    Logger.info("autosyncing: #{asset_kind} #{id} #{inspect(params)}")

    case Repo.get_by(asset_kind, id: id) do
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
end
