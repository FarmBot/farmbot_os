defmodule FarmbotOS.Asset.Command do
  @moduledoc """
  A collection of functions that _write_ to the DB
  """
  require Logger
  alias FarmbotOS.{Asset, Asset.Repo}

  alias FarmbotOS.Asset.{
    Device,
    FarmEvent,
    FarmEvent,
    FarmwareEnv,
    FbosConfig,
    FirmwareConfig,
    Regimen,
    Sensor,
    PointGroup,
    SensorReading,
    Sequence
  }

  @typedoc "String kind that should be turned into an Elixir module."
  @type kind :: String.t()

  @typedoc "key/value map of changes"
  @type params :: map()

  @typedoc "remote database id"
  @type id :: integer()

  @doc """
  Will insert, update or delete data in the local database.
  This function will raise if error occur.
  """
  @callback update(kind, params, id) :: :ok | no_return()

  def update(kind, id, params) when is_binary(kind) do
    update(as_module!(kind), id, params)
  end

  def update(Device, id, nil) do
    Asset.delete_device!(id)
    :ok
  end

  def update(Device, _id, params) do
    Asset.update_device!(params)
    :ok
  end

  def update(FbosConfig, id, nil) do
    Asset.delete_fbos_config!(id)
    :ok
  end

  def update(FbosConfig, _id, params) do
    Asset.update_fbos_config!(params)
    :ok
  end

  def update(FirmwareConfig, id, nil) do
    Asset.delete_firmware_config!(id)
    :ok
  end

  def update(FirmwareConfig, _id, params) do
    Asset.update_firmware_config!(params)
    :ok
  end

  # Deletion use case:
  # TODO(Connor) put checks for deleting Device, FbosConfig and FirmwareConfig

  def update(FarmEvent, id, nil) do
    farm_event = Asset.get_farm_event(id)
    farm_event && Asset.delete_farm_event!(farm_event)
    :ok
  end

  def update(Regimen, id, nil) do
    regimen = Asset.get_regimen(id)
    regimen && Asset.delete_regimen!(regimen)
    :ok
  end

  def update(asset_kind, id, nil) do
    old = Repo.get_by(as_module!(asset_kind), id: id)
    old && Repo.delete!(old)
    :ok
  end

  def update(FarmwareEnv, id, params) do
    Asset.upsert_farmware_env_by_id(id, params)
    :ok
  end

  def update(FarmEvent, id, params) do
    old = Asset.get_farm_event(id)

    if old,
      do: Asset.update_farm_event!(old, params),
      else: Asset.new_farm_event!(params)

    :ok
  end

  def update(Regimen, id, params) do
    old = Asset.get_regimen(id)

    if old,
      do: Asset.update_regimen!(old, params),
      else: Asset.new_regimen!(params)

    :ok
  end

  def update(Sensor, id, params) do
    old = Asset.get_sensor(id)

    if old,
      do: Asset.update_sensor!(old, params),
      else: Asset.new_sensor!(params)

    :ok
  end

  def update(SensorReading, id, params) do
    old = Asset.get_sensor_reading(id)

    if old,
      do: Asset.update_sensor_reading!(old, params),
      else: Asset.new_sensor_reading!(params)

    :ok
  end

  def update(Sequence, id, params) do
    old = Asset.get_sequence(id)

    if old,
      do: Asset.update_sequence!(old, params),
      else: Asset.new_sequence!(params)

    :ok
  end

  def update(PointGroup, id, nil) do
    point_group = Asset.get_point_group(id: id)
    point_group && Asset.delete_point_group!(point_group)
    :ok
  end

  def update(PointGroup, id, params) do
    old = Asset.get_point_group(id: id)

    if old,
      do: Asset.update_point_group!(old, params),
      else: Asset.new_point_group!(params)

    :ok
  end

  # Catch-all use case:
  def update(asset_kind, id, params) do
    mod = as_module!(asset_kind)

    case Repo.get_by(mod, id: id) do
      nil ->
        struct!(mod)
        |> mod.changeset(params)
        |> Repo.insert!()

      asset ->
        mod.changeset(asset, params)
        |> Repo.update!()
    end

    :ok
  end

  defp as_module!("Device"), do: Asset.Device
  defp as_module!("FarmEvent"), do: Asset.FarmEvent
  defp as_module!("FarmwareEnv"), do: Asset.FarmwareEnv
  defp as_module!("FbosConfig"), do: Asset.FbosConfig
  defp as_module!("FirmwareConfig"), do: Asset.FirmwareConfig
  defp as_module!("Peripheral"), do: Asset.Peripheral
  defp as_module!("PinBinding"), do: Asset.PinBinding
  defp as_module!("Point"), do: Asset.Point
  defp as_module!("PointGroup"), do: Asset.PointGroup
  defp as_module!("Regimen"), do: Asset.Regimen
  defp as_module!("Sensor"), do: Asset.Sensor
  defp as_module!("SensorReading"), do: Asset.SensorReading
  defp as_module!("Sequence"), do: Asset.Sequence
  defp as_module!("Tool"), do: Asset.Tool

  defp as_module!(module) when is_atom(module) do
    as_module!(List.last(Module.split(module)))
  end

  defp as_module!(kind) when is_binary(kind) do
    raise("""
    Unknown kind: #{kind}
    """)
  end
end
