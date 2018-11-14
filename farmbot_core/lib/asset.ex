defmodule Farmbot.Asset do
  alias Farmbot.Asset.{
    Repo,
    Device,
    FarmwareEnv,
    FarmwareInstallation,
    FarmEvent,
    FbosConfig,
    FirmwareConfig,
    PinBinding,
    Regimen,
    PersistentRegimen,
    Sequence
  }

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

  def fbos_config() do
    Repo.one(FbosConfig) || %FbosConfig{}
  end

  def fbos_config(field) do
    Map.fetch!(fbos_config(), field)
  end

  ## End FbosConfig

  ## Begin FirmwareConfig

  def firmware_config() do
    Repo.one(FirmwareConfig) || %FirmwareConfig{}
  end

  def firmware_config(field) do
    Map.fetch!(firmware_config(), field)
  end

  ## End FirmwareConfig

  ## Begin PersistentRegimen

  def upsert_persistent_regimen(%Regimen{} = regimen, %FarmEvent{} = farm_event, params \\ %{}) do
    q =
      from(pr in PersistentRegimen,
        where: pr.regimen_id == ^regimen.local_id and pr.farm_event_id == ^farm_event.local_id
      )

    pr = Repo.one(q) || %PersistentRegimen{}

    pr
    |> Repo.preload([:regimen, :farm_event])
    |> PersistentRegimen.changeset(params)
    |> Ecto.Changeset.put_assoc(:regimen, regimen)
    |> Ecto.Changeset.put_assoc(:farm_event, farm_event)
    |> Repo.insert_or_update()
  end

  ## End PersistentRegimen

  ## Begin PinBinding

  @doc "Lists all available pin bindings"
  def list_pin_bindings do
    Repo.all(PinBinding)
  end

  ## End PinBinding

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
      else
        %FarmwareEnv{}
      end

    FarmwareEnv.changeset(fwe, params)
    |> Repo.insert_or_update()
  end

  ## End FarmwareEnv
end
