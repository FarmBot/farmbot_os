defmodule FarmbotCore.Asset do
  @moduledoc """
  Top level module, with some helpers. Persists application resources to disk.
  Submodules of this module usually (but not always) correspond to a
  resource in the REST API. See official REST API docs for details.
  """

  alias FarmbotCore.Asset.{
    Repo,
    Device,
    DeviceCert,
    DiagnosticDump,
    FarmwareEnv,
    FarmwareInstallation,
    FarmEvent,
    FbosConfig,
    FirmwareConfig,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    RegimenInstance,
    Sequence,
    Sensor,
    Tool
  }
  alias FarmbotCore.AssetSupervisor

  import Ecto.Query

  ## Begin Device

  def device() do
    Repo.one(Device) || %Device{}
  end

  ## End Device

  ## Begin FarmEvent

  @doc "Returns a FarmEvent by its API id."
  def get_farm_event(id) do
    Repo.get_by(FarmEvent, id: id)
  end

  def update_farm_event!(farm_event, params) do
    FarmEvent.changeset(farm_event, params)
    |> Repo.update!()
  end

  ## End FarmEvent

  ## Begin FbosConfig

  @doc "Gets the local config"
  def fbos_config() do
    Repo.one(FbosConfig) || %FbosConfig{}
  end

  @doc "Gets a field on the local config."
  def fbos_config(field) do
    Map.fetch!(fbos_config(), field)
  end

  @doc """
  This function updates Farmbot OS's local database. It will **NOT** send any
  HTTP requests to the API. To do this, `FarmbotCore.Asset.Private.mark_dirty!/2`
  is almost certainly what you want.
  """
  def update_fbos_config!(fbos_config \\ nil, params) do
    new_data =
      FbosConfig.changeset(fbos_config || fbos_config(), params)
      |> Repo.insert_or_update!()
    AssetSupervisor.cast_child(new_data, {:new_data, new_data})
    new_data
  end

  ## End FbosConfig

  ## Begin FirmwareConfig

  def firmware_config() do
    Repo.one(FirmwareConfig) || %FirmwareConfig{}
  end

  def firmware_config(field) do
    Map.fetch!(firmware_config(), field)
  end

  def update_firmware_config!(firmware_config \\ nil, params) do
    new_data =
      FirmwareConfig.changeset(firmware_config || firmware_config(), params)
      |> Repo.insert_or_update!()
    AssetSupervisor.cast_child(new_data, {:new_data, new_data})
    new_data
  end

  ## End FirmwareConfig

  ## Begin RegimenInstance

  def upsert_regimen_instance!(%Regimen{} = regimen, %FarmEvent{} = farm_event, params \\ %{}) do
    q =
      from(pr in RegimenInstance,
        where: pr.regimen_id == ^regimen.local_id and pr.farm_event_id == ^farm_event.local_id
      )

    pr = Repo.one(q) || %RegimenInstance{}

    pr
    |> Repo.preload([:regimen, :farm_event])
    |> RegimenInstance.changeset(params)
    |> Ecto.Changeset.put_assoc(:regimen, regimen)
    |> Ecto.Changeset.put_assoc(:farm_event, farm_event)
    |> Repo.insert_or_update!()
  end

  def update_regimen_instance!(%RegimenInstance{} = pr, params \\ %{}) do
    pr
    |> RegimenInstance.changeset(params)
    |> Repo.update!()
  end

  ## End RegimenInstance

  ## Begin PinBinding

  @doc "Lists all available pin bindings"
  def list_pin_bindings do
    Repo.all(PinBinding)
  end

  ## End PinBinding

  ## Begin Point

  def get_point(params) do
    Repo.get_by(Point, params)
  end

  ## End Point

  ## Begin Regimen

  @doc "Get a regimen by it's API id and FarmEvent API id"
  def get_regimen!(params) do
    Repo.get_by!(Regimen, params)
  end

  ## End Regimen

  ## Begin Sequence

  @doc "Get a sequence by it's API id"
  def get_sequence!(params) do
    Repo.get_by!(Sequence, params)
  end

  def get_sequence(params) do
    Repo.get_by(Sequence, params)
  end

  ## End Sequence

  ## Begin FarmwareInstallation

  @doc "Get a FarmwareManifest by it's name."
  def get_farmware_manifest(package) do
    Repo.all(from(fwi in FarmwareInstallation, select: fwi.manifest))
    |> Enum.find(fn %{package: pkg} -> pkg == package end)
  end

  ## End FarmwareInstallation

  ## Begin FarmwareEnv

  def list_farmware_env() do
    Repo.all(FarmwareEnv)
  end

  def new_farmware_env(params) do
    fwe =
      if params["key"] || params[:key] do
        Repo.get_by(FarmwareEnv, key: params["key"] || params[:key])
      end

    FarmwareEnv.changeset(fwe || %FarmwareEnv{}, params)
    |> Repo.insert_or_update()
  end

  ## End FarmwareEnv

  ## Begin Peripheral

  def get_peripheral(args) do
    Repo.get_by(Peripheral, args)
  end

  ## End Peripheral

  ## Begin Sensor

  def get_sensor(args) do
    Repo.get_by(Sensor, args)
  end

  ## End Sensor

  ## Begin DiagnosticDump

  def new_diagnostic_dump(params) do
    DiagnosticDump.changeset(%DiagnosticDump{}, params)
    |> Repo.insert()
  end

  ## End DiagnosticDump

  ## Begin DeviceCert

  def new_device_cert(params) do
    DeviceCert.changeset(%DeviceCert{}, params)
    |> Repo.insert()
  end

  ## End DeviceCert

  ## Begin Tool

  def get_tool(args) do
    Repo.get_by(Tool, args)
  end

  ## End Tool
end
