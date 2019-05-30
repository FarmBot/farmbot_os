defmodule FarmbotCore.Asset.Command do
  @moduledoc """
  A collection of functions that _write_ to the DB
  """

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

  @callback update(kind, params) :: return_type
  def update(Device, params) do
    Asset.device()
    |> Device.changeset(params)
    |> Repo.update!()
  end

  def update(FbosConfig, params) do
    Asset.update_fbos_config!(params)
  end

  def update(FirmwareConfig, params) do
    Asset.update_firmware_config!(params)
  end

  @callback update(kind, params, id) :: return_type
  def update(FarmwareEnv, params, id) do
    Asset.upsert_farmware_env_by_id(id, params)
  end

  def update(FarmwareInstallation, id, params) do
    Asset.upsert_farmware_env_by_id(id, params)
  end
end
