defmodule Farmbot.Asset do
  @doc "API path for HTTP requests."
  @callback path() :: Path.t()

  @doc "Apply params to a changeset or object."
  @callback changeset(map, map) :: Ecto.Changeset.t()

  alias Farmbot.Asset.{Repo,
    Device,
    FarmEvent,
    FbosConfig,
    FirmwareConfig,
    PinBinding,
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

  def list_persistent_regimens() do
    []
    # raise("FIXME")
  end

  def list_persistent_regimens(_regimen) do
    raise("FIXME")
  end

  def new_persistent_regimen(_regimen, _farm_event) do
    raise("FIXME")
  end

  def get_persistent_regimen(_regimen) do
    raise("FIXME")
  end

  def update_persistent_regimen(_regimen, _params) do
    raise("FIXME")
  end

  def delete_persistent_regimen(_regimen) do
    raise("FIXME")
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
  def get_regimen!(_id, _farm_event_id) do
    raise("FIXME")
  end

  @doc "Get all regimens using a particular sequence by it's API id"
  def get_regimens_using_sequence(_sequence_id) do
    raise("FIXME")
  end

  ## End Regimen

  ## Begin Sequence

  @doc "Get a sequence by it's API id"
  def get_sequence!(id) do
    Repo.get_by!(Sequence, id: id)
  end

  ## End Sequence
end
