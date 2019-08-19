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
    FirstPartyFarmware,
    FarmwareInstallation,
    FarmEvent,
    FbosConfig,
    FirmwareConfig,
    Peripheral,
    PinBinding,
    Point,
    PublicKey,
    Regimen,
    RegimenInstance,
    Sequence,
    Sensor,
    SensorReading,
    Tool
  }

  alias FarmbotCore.AssetSupervisor

  import Ecto.Query

  ## Begin Device

  def device() do
    Repo.one(Device) || %Device{}
  end

  def update_device!(params) do
    device()
    |> Device.changeset(params)
    |> Repo.insert_or_update!()
  end

  def delete_device!(id) do
    if device = Repo.get_by(Device, id: id) do
      Repo.delete!(device)
    end
    :ok
  end

  ## End Device

  ## Begin FarmEvent

  def new_farm_event!(params) do
    %FarmEvent{}
    |> FarmEvent.changeset(params)
    |> Repo.insert!()
  end

  @doc "Returns a FarmEvent by its API id."
  def get_farm_event(id) do
    Repo.get_by(FarmEvent, id: id)
  end

  def update_farm_event!(farm_event, params) do
    farm_event = 
      farm_event |> 
      FarmEvent.changeset(params) 
      |> Repo.update!()

    if farm_event.executable_type == "Regimen" do
      regimen_instance = get_regimen_instance(farm_event)
      if regimen_instance do
        regimen_instance
        |> Repo.preload([:farm_event, :regimen])
        |> RegimenInstance.changeset(%{updated_at: DateTime.utc_now()})
        |> Repo.update!()
      end
    end

    farm_event
  end

  def delete_farm_event!(farm_event) do
    ri = get_regimen_instance(farm_event)
    ri && Repo.delete!(ri)
    Repo.delete!(farm_event)
  end

  def add_execution_to_farm_event!(%FarmEvent{} = farm_event, params \\ %{}) do
    %FarmEvent.Execution{}
    |> FarmEvent.Execution.changeset(params)
    |> Ecto.Changeset.put_assoc(:farm_event, farm_event)
    |> Repo.insert!()
  end

  def get_farm_event_execution(%FarmEvent{} = farm_event, scheduled_at) do
    Repo.one(
      from e in FarmEvent.Execution, 
        where: e.farm_event_local_id == ^farm_event.local_id
        and e.scheduled_at == ^scheduled_at
    )
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

  def delete_fbos_config!(id) do
    if fbos_config = Repo.get_by(FbosConfig, id: id) do
      Repo.delete!(fbos_config)
    end
    :ok
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

  def delete_firmware_config!(id) do
    if firmware_config = Repo.get_by(FirmwareConfig, id: id) do
      Repo.delete!(firmware_config)
    end
    :ok
  end

  ## End FirmwareConfig

  ## Begin RegimenInstance

  def get_regimen_instance(%FarmEvent{} = farm_event) do
    regimen = Repo.one(from r in Regimen, where: r.id == ^farm_event.executable_id)
    regimen && Repo.one(from ri in RegimenInstance, where: ri.regimen_id == ^regimen.local_id and ri.farm_event_id == ^farm_event.local_id)    
  end

  def new_regimen_instance!(%FarmEvent{} = farm_event, params \\ %{}) do
    regimen = Repo.one!(from r in Regimen, where: r.id == ^farm_event.executable_id)
    RegimenInstance.changeset(%RegimenInstance{}, params)
    |> Ecto.Changeset.put_assoc(:regimen, regimen)
    |> Ecto.Changeset.put_assoc(:farm_event, farm_event)
    |> Repo.insert!()
  end

  def delete_regimen_instance!(%RegimenInstance{} = ri) do
    Repo.delete!(ri)
  end
  
  def add_execution_to_regimen_instance!(%RegimenInstance{} = ri, params \\ %{}) do
    %RegimenInstance.Execution{}
    |> RegimenInstance.Execution.changeset(params)
    |> Ecto.Changeset.put_assoc(:regimen_instance, ri)
    |> Repo.insert!()
  end

  def get_regimen_instance_execution(%RegimenInstance{} = ri, scheduled_at) do
    Repo.one(
      from e in RegimenInstance.Execution, 
        where: e.regimen_instance_local_id == ^ri.local_id
        and e.scheduled_at == ^scheduled_at
    )
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

  ## Begin PublicKey

  def get_public_key(id) do
    Repo.get_by(PublicKey, id: id)
  end

  def new_public_key!(params) do
    %PublicKey{}
    |> PublicKey.changeset(params)
    |> Repo.insert!()
  end

  def update_public_key!(public_key, params) do
    public_key
    |> PublicKey.changeset(params)
    |> Repo.update!()
  end

  def delete_public_key!(public_key) do
    Repo.delete!(public_key)
  end

  def new_public_key_from_home!() do
    public_key_path = Path.join([System.get_env("HOME"), ".ssh", "id_rsa.pub"])
    public_key = File.read!(public_key_path)
    %PublicKey{}
    |> PublicKey.changeset(%{public_key: public_key})
    |> Repo.insert()
  end

  def new_public_key_from_string!(public_key) do
    %PublicKey{}
    |> PublicKey.changeset(%{public_key: public_key})
    |> Repo.insert()
  end
  
  ## End PublicKey

  ## Begin Regimen

  @doc "Get a regimen by it's API id"
  def get_regimen(id) do
    Repo.get_by(Regimen, id: id)
  end

  @doc "Enter a new regimen into the DB"
  def new_regimen!(params) do
    %Regimen{}
    |> Regimen.changeset(params)
    |> Repo.insert!()
  end

  def delete_regimen!(regimen) do
    regimen_instances = Repo.all(from ri in RegimenInstance, where: ri.regimen_id == ^regimen.local_id)
    for ri <- regimen_instances do
      IO.puts "deleting regimen instance: #{inspect(ri)}"
      delete_regimen_instance!(ri)
    end
    Repo.delete!(regimen)
  end

  @doc "Update an existing regimen"
  def update_regimen!(regimen, params) do
    regimen_instances = Repo.all(from ri in RegimenInstance, where: ri.regimen_id == ^regimen.local_id)
    |> Repo.preload([:farm_event, :regimen])
    for ri <- regimen_instances do
      ri
      |> RegimenInstance.changeset(%{updated_at: DateTime.utc_now()})
      |> Repo.update!()
    end

    regimen
    |> Regimen.changeset(params)
    |> Repo.update!()
  end

  ## End Regimen

  ## Begin Sequence

  @doc "Get a sequence by it's API id"
  def get_sequence(id) do
    Repo.get_by(Sequence, id: id)
  end

  def update_sequence!(%Sequence{} = sequence, params \\ %{}) do
    sequence_id = sequence.id
    farm_events = Repo.all(from f in FarmEvent, 
      where: f.executable_type == "Sequence" 
      and f.executable_id == ^sequence_id)

    regimen_instances = RegimenInstance
    |> Repo.all()
    |> Repo.preload([:regimen, :farm_event])
    |> Enum.filter(fn
      %{regimen: %{regimen_items: items}} -> 
        Enum.find(items, fn
          %{sequence_id: ^sequence_id} -> true
          %{sequence_id: _} -> true
      end)

      %{regimen: nil} -> false
    end)

    for asset <- farm_events ++ regimen_instances do
      FarmbotCore.AssetSupervisor.update_child(asset)
    end

    Sequence.changeset(sequence, params)
    |> Repo.update!()
  end

  def new_sequence!(params \\ %{}) do
    Sequence.changeset(%Sequence{}, params)
    |> Repo.insert!()
  end

  ## End Sequence

  ## Begin FarmwareInstallation

  @doc "Get a FarmwareManifest by it's name."
  def get_farmware_manifest(package) do
    first_party_farmwares = Repo.all(from(fwi in FirstPartyFarmware, select: fwi.manifest))
    regular_farmwares = Repo.all(from(fwi in FarmwareInstallation, select: fwi.manifest))
    Enum.find(
      first_party_farmwares ++ regular_farmwares, 
      fn %{package: pkg} -> pkg == package end
    )
  end

  def get_farmware_installation(package) do
    first_party_farmwares = Repo.all(from(fwi in FirstPartyFarmware))
    regular_farmwares = Repo.all(from(fwi in FarmwareInstallation))
    Enum.find(
      first_party_farmwares ++ regular_farmwares, 
      fn %{manifest: %{package: pkg}} -> pkg == package end
    )
  end

  def upsert_farmware_manifest_by_id(id, params) do
    fwi = Repo.get_by(FarmwareInstallation, id: id) || %FarmwareInstallation{}
    FarmwareInstallation.changeset(fwi, params)
    |> Repo.insert_or_update()
  end

  def upsert_first_party_farmware_manifest_by_id(id, params) do
    fwi = Repo.get_by(FirstPartyFarmware, id: id) || %FirstPartyFarmware{}
    FirstPartyFarmware.changeset(fwi, params)
    |> Repo.insert_or_update()
  end

  ## End FarmwareInstallation

  ## Begin FarmwareEnv

  def list_farmware_env() do
    Repo.all(FarmwareEnv)
  end

  def upsert_farmware_env_by_id(id, params) do
    fwe = Repo.get_by(FarmwareEnv, id: id) || %FarmwareEnv{}

    FarmwareEnv.changeset(fwe, params)
    |> Repo.insert_or_update()
  end

  def new_farmware_env(params) do
    key = params["key"] || params[:key]
    fwe = with key when is_binary(key) <- key,
      [fwe | _] <- Repo.all(from fwe in FarmwareEnv, where: fwe.key == ^key) do
      fwe
    else
      _ -> %FarmwareEnv{}
    end

    FarmwareEnv.changeset(fwe, params)
    |> Repo.insert_or_update()
  end

  ## End FarmwareEnv

  ## Begin Peripheral

  def get_peripheral(args) do
    Repo.get_by(Peripheral, args)
  end

  def get_peripheral_by_pin(pin) do
    Repo.get_by(Peripheral, pin: pin)
  end

  ## End Peripheral

  ## Begin Sensor

  def get_sensor(id) do
    Repo.get_by(Sensor, id: id)
  end

  def get_sensor_by_pin(pin) do
    Repo.get_by(Sensor, pin: pin)
  end

  def new_sensor!(params) do
    Sensor.changeset(%Sensor{}, params)
    |> Repo.insert!()
  end
  
  def update_sensor!(sensor, params) do
    sensor
    |> Sensor.changeset(params)
    |> Repo.update!()
  end

  ## End Sensor

  ## Begin SensorReading

  def get_sensor_reading(id) do
    Repo.get_by(SensorReading, id: id)
  end

  def new_sensor_reading!(params) do
    SensorReading.changeset(%SensorReading{}, params)
    |> Repo.insert!()
  end

  def update_sensor_reading!(sensor_reading, params) do
    sensor_reading
    |> SensorReading.changeset(params)
    |> Repo.update!()
  end

  ## End SensorReading

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

  def get_device_cert(args) do
    Repo.get_by(DeviceCert, args)
  end

  def update_device_cert(cert, params) do
    cert
    |> DeviceCert.changeset(params)
    |> Repo.update()
  end

  ## End DeviceCert

  ## Begin Tool

  def get_tool(args) do
    Repo.get_by(Tool, args)
  end

  ## End Tool
end
