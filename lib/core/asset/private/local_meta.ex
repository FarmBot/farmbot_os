defmodule FarmbotOS.Asset.Private.LocalMeta do
  @moduledoc """
  Existence of LocalMeta is a hint to Farmbot that
  an Asset needs to be reconciled with the remote API.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias FarmbotOS.Asset.{
    Repo,
    Device,
    FarmEvent,
    FarmwareEnv,
    FbosConfig,
    FirmwareConfig,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    SensorReading,
    Sensor,
    Sequence,
    Tool
  }

  schema "local_metas" do
    field(:status, :string)
    field(:table, :string)
    field(:asset_local_id, :binary_id)
    field(:monitor, :boolean, default: true)

    belongs_to(:device, Device,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:farm_event, FarmEvent,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:farmware_env, FarmwareEnv,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:fbos_config, FbosConfig,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:firmware_config, FirmwareConfig,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:peripheral, Peripheral,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:pin_binding, PinBinding,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:point, Point,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:regimen, Regimen,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:sensor_reading, SensorReading,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:sensor, Sensor,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:sequence, Sequence,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )

    belongs_to(:tool, Tool,
      foreign_key: :asset_local_id,
      type: :binary_id,
      references: :local_id,
      define_field: false
    )
  end

  def changeset(local_meta, params \\ %{}) do
    local_meta
    |> cast(params, [:table, :status])
    |> validate_required([:asset_local_id, :table])
    |> validate_inclusion(:status, ~w(dirty stale))
    |> validate_inclusion(:table, [
      "devices",
      "tools",
      "peripherals",
      "sensors",
      "sensor_readings",
      "sequences",
      "regimens",
      "pin_bindings",
      "points",
      "point_groups",
      "farm_events",
      "firmware_configs",
      "fbos_configs",
      "farmware_installations",
      "farmware_envs"
    ])
    |> unsafe_validate_unique([:table, :asset_local_id], Repo,
      message: "LocalMeta already exists."
    )
    |> unique_constraint(:table, name: :local_metas_table_asset_local_id_index)
  end
end
