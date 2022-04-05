defmodule FarmbotOS.Asset.SensorReading do
  @moduledoc """
  SensorReadings are descriptors for pins/modes.
  """

  use FarmbotOS.Asset.Schema, path: "/api/sensor_readings"

  schema "sensor_readings" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:mode, :integer)
    field(:pin, :integer)
    field(:value, :integer)
    field(:x, :float)
    field(:y, :float)
    field(:z, :float)
    field(:monitor, :boolean, default: true)
    field(:read_at, :utc_datetime_usec)
    timestamps()
  end

  view sensor_reading do
    %{
      id: sensor_reading.id,
      mode: sensor_reading.mode,
      pin: sensor_reading.pin,
      value: sensor_reading.value,
      x: sensor_reading.x,
      y: sensor_reading.y,
      z: sensor_reading.z,
      read_at: sensor_reading.read_at,
      created_at: sensor_reading.created_at
    }
  end

  def changeset(sensor, params \\ %{}) do
    sensor
    |> cast(params, [
      :id,
      :mode,
      :pin,
      :value,
      :x,
      :y,
      :z,
      :monitor,
      :read_at,
      :created_at,
      :updated_at
    ])
    |> validate_required([])
  end
end
