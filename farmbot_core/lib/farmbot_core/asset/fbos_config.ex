defmodule FarmbotCore.Asset.FbosConfig do
  @moduledoc """
  Farmbot's configuration database
  """

  use FarmbotCore.Asset.Schema, path: "/api/fbos_config"

  schema "fbos_configs" do
    field(:id, :id)

    has_one(:local_meta, FarmbotCore.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    # No longer supported
    field(:firmware_hardware, :string)

    # stateful
    field(:firmware_path, :string)

    # system
    field(:disable_factory_reset, :boolean)
    field(:network_not_found_timer, :integer)
    field(:os_auto_update, :boolean)

    # celeryscript
    field(:sequence_body_log, :boolean)
    field(:sequence_complete_log, :boolean)
    field(:sequence_init_log, :boolean)

    field(:safe_height, :float)
    field(:soil_height, :float)

    # private
    field(:monitor, :boolean, default: true)
    timestamps()
  end

  view fbos_config do
    %{
      id: fbos_config.id,
      updated_at: fbos_config.updated_at,
      disable_factory_reset: fbos_config.disable_factory_reset,
      firmware_hardware: fbos_config.firmware_hardware,
      firmware_path: fbos_config.firmware_path,
      network_not_found_timer: fbos_config.network_not_found_timer,
      os_auto_update: fbos_config.os_auto_update,
      sequence_body_log: fbos_config.sequence_body_log,
      sequence_complete_log: fbos_config.sequence_complete_log,
      sequence_init_log: fbos_config.sequence_init_log,
      safe_height: fbos_config.safe_height,
      soil_height: fbos_config.soil_height,
    }
  end

  def changeset(fbos_config, params \\ %{}) do
    fbos_config
    |> cast(params, [
      :id,
      :created_at,
      :updated_at,
      :monitor,
      :disable_factory_reset,
      :firmware_hardware,
      :firmware_path,
      :network_not_found_timer,
      :os_auto_update,
      :safe_height,
      :sequence_body_log,
      :sequence_complete_log,
      :sequence_init_log,
      :soil_height,
    ])
    |> validate_required([])
  end
end
